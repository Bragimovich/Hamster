# frozen_string_literal: true

class PdfParser
  include Hamster::Loggable

  def initialize(pdf_url, case_id)
    @pdf_url      = pdf_url
    @case_id      = case_id
    @document     = []
    @hash_data    = {}
    reader = PDF::Reader.new(URI.open(@pdf_url))
    reader.pages.each_with_index do |page, page_num|
      break if page.text.nil?

      text_array = remove_footer_lines(page)
      @document << '' # blank line for page spliting
      @document.concat text_array
      break if (page_num != 0 && page.text =~ /(,\s[J]{1}.$)|(Judge(\s+)?\.?$)|(,\sJUDGE\.$)/)
    end
  end

  def parseable?
    # All pdf file has 'Court composed of ... ... ,Judges.' string and denied pdfs are the exception.
    @case_info_block_end_line = find_index("Court composed of") || find_index("Judges")
    @case_info_block_end_line.present?
  end

  def parse
    parse_case_info
    parse_party_info
    @hash_data
  end

  private

  def parse_case_info
    # parsing first page info
    case_info_block = @document[0..@case_info_block_end_line-1].select{|text| text.strip.length > 1}
    lines = []
    case_info_block.each_with_index{|l, i| lines << i if l.include?('*****')}
    if lines.count == 3
      judge_name_block = case_info_block[lines[1] + 1..lines[2] - 1]
      case_number_block = case_info_block[lines[0] + 1..lines[1] - 1]
      if judge_name_block.length == 1
        judge_name_line = judge_name_block.last
        @hash_data[:judge_name] = judge_name_line.gsub(/judge/i, '').strip
      else
        @hash_data[:judge_name] = judge_name_block.select{|l| !l.include?('JUDGE')}.join().strip
      end

      ind = case_number_block.length-1
      while ind > 0 do
        if case_number_block[ind].match(/(\d+)/)
          match_data = case_number_block[ind].match(/[\w\s]*,.*(?:no|number|nos)\.?\s(.*)$/i)
          lower_case_id_line = ind
          if match_data
            @hash_data[:lower_case_id] = match_data[1]
            
            break
          else
            match_data = case_number_block[ind].match(/(\d.*)/)
            @hash_data[:lower_case_id] = match_data[1]

            break
          end
        elsif case_number_block[ind].match(/NO./)
          lower_case_id_line = ind
          @hash_data[:lower_case_id] = 'NO.'
        end
        ind -= 1
      end
      lower_judge_name = case_number_block[lower_case_id_line+1]&.strip || get_lower_judge_name(case_number_block)
      lower_court_name = get_lower_court_name(case_number_block)
    elsif lines.count == 4
      case_number_block = nil
      case_info_block[lines[0]..lines[1]].each do |txt_line|
        if txt_line.match(/(\d+)/)
          case_number_block = case_info_block[lines[0] + 1..lines[1] - 1]
        end
      end

      if case_number_block && check_judge_name_block(case_info_block, [lines[1], lines[2]])
        judge_name_block = case_info_block[lines[1] + 1..lines[2] - 1]
      else
        judge_name_block = case_info_block[lines[2] + 1..lines[3] - 1]
      end

      case_info_block[lines[1]..lines[2]].each do |txt_line|
        if txt_line.match(/(\d+)/)
          case_number_block = case_info_block[lines[1] + 1..lines[2] - 1]
          judge_name_block = case_info_block[lines[2] + 1..lines[3] - 1]
        end
      end

      @hash_data[:judge_name] = judge_name_block.select{|l| !l.include?('JUDGE')}.join().strip
      ind = case_number_block.length-1
      while ind > 0 do
        if case_number_block[ind].match(/(\d+)/)
          match_data = case_number_block[ind].match(/[\w\s]*,.*(?:no|number|nos)\.?\s(.*)$/i)
          lower_case_id_line = ind
          if match_data
            @hash_data[:lower_case_id] = match_data[1]
            
            break
          else
            match_data = case_number_block[ind].match(/(\d.*)/)
            @hash_data[:lower_case_id] = match_data[1]

            break
          end
        elsif case_number_block[ind].match(/NO./)
          lower_case_id_line = ind
          @hash_data[:lower_case_id] = 'NO.'
        end
        ind -= 1
      end
      lower_judge_name = case_number_block[lower_case_id_line+1]&.strip || get_lower_judge_name(case_number_block)
      lower_court_name = get_lower_court_name(case_number_block)
    else
      ind = case_info_block.length-1
      judge_name_line = 0
      started = false

      while ind > 0 do
        if case_info_block[ind].include?('JUDGE') && started == false
          started = true
          judge_name_line = ind - 1
          judge_name_line = judge_name_line - 1 if case_info_block[judge_name_line].strip.upcase.include?('JUDGE')
          judge_name_line = judge_name_line + 1 if case_info_block[judge_name_line].include?('***')
        end
        if started
          if case_info_block[ind].match(/(\d+)/)
            match_data = case_info_block[ind].match(/[\w\s]*,.*(?:no|number|nos)\.?\s(.*)$/i)
            lower_case_id_line = ind
            if match_data
              @hash_data[:lower_case_id] = match_data[1]
  
              break
            else
              match_data = case_info_block[ind].match(/(\d.*)/)
              @hash_data[:lower_case_id] = match_data[1]

              break
            end
          end
        end
        ind -= 1
      end
      @hash_data[:judge_name] = case_info_block[judge_name_line].strip
      lower_judge_name = case_info_block[lower_case_id_line + 1].strip
      lower_court_name = get_lower_court_name(case_info_block)
    end
    @hash_data[:lower_court_name] = lower_court_name
    match_data = /(^.*),\s?[A-Z]/.match(lower_judge_name)
    if match_data
      @hash_data[:lower_judge_name] = match_data[1]
    else
      @hash_data[:lower_judge_name] = lower_judge_name
      @hash_data[:lower_judge_name] = lower_judge_name[0...-1] if lower_judge_name[-1] == ','
    end
    
    ind = find_index("Judges.") || find_index("Court composed of")
    status_as_of_date = ''
    st_line = ind + 1 
    loop do
      @document[st_line].gsub!('and', 'AND') if @document[st_line].include?('and')

      break if @document[st_line].strip.empty? != true && @document[st_line].include?(@document[st_line].upcase) != true

      st_line += 1
    end

    until @document[ind].strip.empty? == false && @document[ind].include?(@document[ind].upcase) == true do
      # finding status_as_of_date line
      ind += 1
    end
  
    while @document[ind].include?(@document[ind].upcase) == true do
      break if @document[ind] == '' && @document[ind + 1] == ''

      status_as_of_date = status_as_of_date.to_s + ' ' + @document[ind].strip
      ind += 1
    end

    @hash_data[:status_as_of_date] = status_as_of_date.strip
    if status_as_of_date.length > 250
      # saving only 250 characters of first sentence.
      @hash_data[:status_as_of_date] = status_as_of_date.split('. ').first.strip[0..250]
      # saving all status to case_description
      @hash_data[:case_description] = "full status:#{status_as_of_date.strip}"
    end
  end

  def parse_party_info
    party_data = get_party_data

    return if party_data.empty?

    party_hash_array = []
    party_array      = get_party_per_block(party_data.reject(&:empty?))
    party_array.each do |party|
      party_hash_array << get_party_infos_from(party)
    end
    @hash_data[:party_info] = party_hash_array.flatten.compact
    logger.debug "Parsed party count is #{party_array.count}"
  end

  def get_party_data
    ind = @case_info_block_end_line + 1
    until @document[ind].strip.empty? == false && @document[ind].include?(@document[ind].upcase) == true do
      ind += 1
    end  
    while @document[ind].include?(@document[ind].upcase) == true do
      break if @document[ind] == '' && @document[ind + 1] == ''

      ind += 1
    end

    party_data = []
  
    while ind < @document.count - 1 do
      # Skipping because this sentence is not party text
      ind += 1 if @document[ind].include?('Supreme Court as Judge Pro Tempore.')

      break if @document[ind].split.join.match(/(^[A-Z]+\w+,J\.$)|(Judge\.?$)|(Tempore.$)|(,JUDGE\.$)/)
      break if @document[ind].include?('VIDRINE, Judge Pro Tempore')
      break if @document[ind].include?('SAUNDERS, Judge')

      if @document[ind] =~ /(concurs|dissents|reasons|decision|judge)/i
        # reject a sentence that is no party block
      else
        # replacing typo issues
        if @document[ind].include?('COUSEL FOR')
          party_data << @document[ind].gsub('COUSEL', 'COUNSEL')
        elsif @document[ind].strip == 'DEFENDANT/APPELLANT:'
          party_data << 'COUNSEL FOR DEFENDANT/APPELLANT:'
        else
          party_data << @document[ind]
        end
      end
      ind += 1
    end
    party_data
  end

  def get_party_per_block(party_data)
    party_array = []
    block_start_line = 0
    block_end_line = 0
    prev_end_line = 0
    state_line = 0
    line_number = 0
    has_city_state = false
    while line_number < party_data.count do
      text_line = party_data[line_number].strip
      if text_line =~ /\d{5}/ || text_line =~ /(^[A-Z]\w.*,\s[A-Z]{2})$/ 
        has_city_state = true
      end
      party_block = []
      if (has_city_state && text_line.match(/^(COUNSEL|CO-COUNSEL|ATTORNEY|ATTORNEYS|PRO|PRO-SE|INTERVENOR)/i)) && !text_line.match(/law|general/i)
        party_block.concat party_data[block_start_line..line_number]
        has_city_state = false
        counsel_party_line = party_data[line_number + 1]

        return party_array if counsel_party_line.nil?

        counsel_party_tab_size = counsel_party_line.length - counsel_party_line.lstrip.length
        if counsel_party_tab_size.zero?
          party_array << party_block
          block_start_line = line_number + 1
        else
          counsel_line_num = line_number
          while counsel_line_num < party_data.count do
            counsel_line_num += 1
            party_line = party_data[counsel_line_num]
            if (counsel_party_tab_size - tab_size(party_line)).abs > 0
              block_start_line = counsel_line_num
              line_number = counsel_line_num
              party_array << party_block
              break
            else
              party_block << party_line
            end
          end
        end
      elsif (has_city_state && text_line.match(/(\(\d{3}\)\s\d{3}-\d{4})/))
        # check phone number line
        if party_data[line_number + 1]
          unless party_data[line_number + 1].match(/^(COUNSEL|CO-COUNSEL|ATTORNEY|ATTORNEYS|PRO|PRO-SE|INTERVENOR)/i)
            party_block.concat party_data[block_start_line..line_number]
            block_start_line = line_number + 1
            has_city_state = false
            party_array << party_block
          end
        end
      end
      line_number += 1
    end
    party_array
  end

  def get_party_infos_from(party)
    if party.length < 5
      logger.debug "wrong party data: #{party} from #{@pdf_url}"
      return
    end

    party_infos    = []
    counsel_fors   = []
    street_address = ''
    party_type     = ''
    law_firm_line  = 0
    address_line1  = 0
    address_line2  = 0
    start_counsel_line = 0
    party_description = party.map(&:strip).join(', ')
    party.each_with_index do |text_line, ind|
      if text_line =~ /\d{5}/ || text_line.strip =~ /(^[A-Z]\w.*,\s[A-Z]{2})$/ 
        # ----- Address line ----
        law_firm_line = ind - 2
        address_line1 = ind - 1
        address_line2 = ind
        street_address = party[address_line1]
        # Checking if the street address is second line
        law_firm_text = party[law_firm_line].downcase
        if law_firm_text.include?('street') || law_firm_text.include?('square') || law_firm_text.upcase.include?('P. O. BOX')
          street_address = [party[address_line1], party[law_firm_line]].join(', ') 
          street_address = [party[law_firm_line], party[address_line1]].join(', ') if party[law_firm_line].include?('street')
          law_firm_line = law_firm_line - 1
        end
      elsif text_line.strip.match(/^(counsel|co-counsel|attorney|attorneys|pro+)(\s|-)(for|se)+/i)
        start_counsel_line = ind
        party_type = 
          if party[start_counsel_line].upcase[-5, 5].include?('FOR')
            party_next_line = party[start_counsel_line + 1]
            if party_next_line&.match(/defendants|appellees|plaintiff|appellant/i)
              type = 
                if party_next_line.include?('–')
                  party_next_line.split('–').first.strip
                elsif party_next_line.include?('-')
                  party_next_line.split('-').first.strip
                else
                  party_next_line
                end
              [party[start_counsel_line], type].join(' ')
            else
              party[start_counsel_line]
            end
          else
            party[start_counsel_line]
          end
        break
      end
    end

    match_data = /([\w\s]+)\s*,\s*(\w*)\s*(\d{5}(?:-?\d{4})?)$/.match(party[address_line2])
    match_data = match_data || /(^[A-Z]\w.*),(\s[A-Z]{2})$/.match(party[address_line2])
    if match_data.nil?
      # '-----Skipping for not found matched address-------', party
      return
    end    

    if law_firm_line > 0
      party[0..law_firm_line-1].each do |name|
        next if name.strip.length < 3
        party_hash = {
          court_id: 434,
          case_id: @case_id,
          is_lawyer: true,
          party_name: name.strip,
          party_type: party_type.strip,
          party_law_firm: party[law_firm_line].strip,
          party_address: street_address,
          party_city: match_data[1],
          party_state: match_data[2],
          party_zip: match_data[3],
          party_description: party_description,
          data_source_url: @pdf_url
        }
        party_hash[:md5_hash] = Digest::MD5.new.hexdigest(party_hash.map{|field| field.to_s}.join)
        party_infos << party_hash
      end
    else
      if party[0].strip.length > 3
        party_hash = {
          court_id: 434,
          case_id: @case_id,
          is_lawyer: true,
          party_name: party[0].strip,
          party_type: party_type.strip,
          party_law_firm: nil,
          party_address: street_address,
          party_city: match_data[1],
          party_state: match_data[2],
          party_zip: match_data[3],
          party_description: party_description,
          data_source_url: @pdf_url
        }
        party_hash[:md5_hash] = Digest::MD5.new.hexdigest(party_hash.map{|field| field.to_s}.join)
        party_infos << party_hash
      end
    end

    return party_infos if start_counsel_line.zero?

    counsel_line_text = party[start_counsel_line]
    # Checking whether the counsel line has included the party type
    if counsel_line_text.upcase[-5,5].include?('FOR')
      party[start_counsel_line + 1..party.count].each do |text_line|
        match = text_line.match(/(.*)[-|–](.*)/)
        if match.to_a.count == 3
          counsel_fors << [match[1], match[2]]
        else
          counsel_fors << text_line.split('-')
        end
      end
      counsel_fors = counsel_fors.flatten
      party_type = counsel_fors.shift
    else # Case of including the party type
      match_data = party[start_counsel_line].match(/for\s+([^:]*):?/im)
      if match_data
        party_type = match_data[1]
      else
        party_type = party[start_counsel_line]
      end
      if party[start_counsel_line + 1]&.include?(';')
        counsel_fors << party[start_counsel_line + 1..party.count].join(' ').split(';')
      else
        counsel_fors << party[start_counsel_line + 1..party.count]
      end
    end

    counsel_fors.flatten.each do |name|
      party_hash = {
        court_id: 434,
        case_id: @case_id,
        is_lawyer: false,
        party_name: name.strip,
        party_type: party_type.strip,
        party_description: party_description,
        data_source_url: @pdf_url
      }
      party_hash[:md5_hash] = Digest::MD5.new.hexdigest(party_hash.map{|field| field.to_s}.join)
      party_infos << party_hash
    end
    party_infos
  end
  
  def find_index(string)
    check = @document.select{|e| e.include? "#{string}"}
    ind = @document.index check[0]
  end
  
  def remove_footer_lines(page)
    text_array = page.text.split("\n")
    page_footer_line = nil
    text_array.each_with_index do |text, line|
      page_footer_line = line if text.include?('_'*3)
    end
    text_array -= text_array[page_footer_line..text_array.count] if page_footer_line
    text_array
  end

  def tab_size(string)
    return 0 unless string
    string.length - string.lstrip.length
  end

  def get_lower_judge_name(data)
    data.each do |line|
      return line.strip if line.match(/JUDGE/)
    end
  end

  def get_lower_court_name(data)
    data.each do |line|
      return line.strip if line.match(/COURT/)
    end
  end

  def check_judge_name_block(data, lines)
    data[lines[0]..lines[1]].each do |line|
      return true if line.match(/JUDGE/)
    end

    return false
  end
end
