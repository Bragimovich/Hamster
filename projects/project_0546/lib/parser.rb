# frozen_string_literal: true

class Parser < Hamster::Parser
  attr_reader :all_info_hash
  COLUMNS_ALIAS = {'Date' => 'activity_date', 'Docket Numbers' => 'case_ids', 'Decision-maker(s)' => 'judge_name', 'Opinion Type' => 'activity_type', 'Case Name' => 'case_name', 'Collection' => 'court_type'}

  def initialize(doc)
    self.html = doc
    @all_info_hash = scan_available_info
    @case_name = check_case_name
  end

  def html=(doc)
    @html = Nokogiri::HTML5(doc.force_encoding("utf-8"))
  end

  def set_base_details(court_type, case_id, case_num)
    @case_id = case_id.squish
    @base_details = {court_id: Manager::COURTS[court_type], case_id: case_id,  data_source_url: "https://nmonesource.com/nmos/#{court_type}/en/item/#{case_num}/index.do"}
    check_lower_data
  end

  def check_count_pages
    html.at_css("ul.pager").css('li').map { |el| el.at_css('a').attr('href')[/(?<=page=)\d+$/].to_i rescue nil }.compact.max rescue 1
  end

  def list_links
    list = html.css("div.documentList ul[class='collectionItemList list-expanded'] li")
    return [] if list.empty?
    list.map { |el| el.at_css("div.metadata div.subinfo h3 span.title a").attr('href') }
  end

  def find_pdf_link
    link = html.at_css("div.documents a[target='_blank']").attr('href') rescue nil
    link = html.at_css("li.documents a[target='_blank']").attr('href') rescue nil unless link
    link
  end

  def scan_pdf(raw_content)
    content = raw_content.squeeze(' ').first(15000)

    lower_court_match = [
      'APPEALS FROM', 'APPEAL FROM', 'ORIGINAL PROCEEDING', 'ORIGINAL PROCEEDINGS', 'CERTIFICATION FROM', 'INTERLOCUTORY APPEAL FROM', 
      'DISCIPLINARY PROCEEDING', 'PROCEEDINGS', 'INTERLOCUTORY APPEAL', 'ADMINISTRATIVE'
    ]

    regexp_find_limit = /(OPINION|DECISION|AMENDED ORDER|DISPOSITIONAL ORDER|PUBLIC CENSURE|DISPOSITIONAL|ORDER|MEMORANDUM OPINION)/
    regexp_party_types = /(?i:spondent|fendant|tioner|llant|aintiff|venor|nterest|ppellee|nsurer|orker|sciplinary|micus|ppellees|Third[ -]?Party|hildren|Guardian.?Ad.?Litem|ssistant|Amici)/     
    regexp_find_judges = /(?<=\s)[A-Z][a-z\.].*?(?=,|Judge|Secretar|H.+? Officer|Chairmans?|Chairs?)/m
    main_part_last_index = content =~ /(?<!IS SO)(?<=\n| )#{regexp_find_limit}(?=\n{1,}| )(?!.+(?<!IS SO)(?<=\n| )#{regexp_find_limit}(?=\n{1,}| ).*\Z)/m
    main_part_last_index = -1 unless main_part_last_index
    content = content[..main_part_last_index]   
    case_type = content.match?(/\n?\s?vs?\.\s?(N[oO][:\.] ?#{case_id} ?)?\n+/) ? 'v' : 'in re'

    lower_court_name_match = content[/(?<=#{lower_court_match.join('|')})[^a-z,]+(?!.+?(#{lower_court_match.join('|')})[^a-z,]+.*\Z)/m]
    lower_court_name = clean_lower_court_name(lower_court_name_match) if lower_court_name_match

    if lower_court_name
      begin
        lower_judge_name = content[/(?<=#{Regexp.escape(lower_court_name)}).+/m]
        lower_judge_name = content.match?(/\n ?COUNSEL ?\n/) ? lower_judge_name[/.*?(?=\n ?COUNSEL ?\n)/m] : lower_judge_name[..200]
        lower_judge_name = lower_judge_name[/.*?(Judges?|H.+? Officers?|Secretary?|Chairmans?|Chairs?) ?(\n|,| |\.|\()/m]
        lower_judge_name = lower_judge_name[/#{regexp_find_judges}/].strip.sub(/District/i, '').sub(/Circuit/i, '').sub(/Secretary?/i, '').sub(/^,/, '')
      rescue => e
       lower_judge_name = nil
      end
      if lower_judge_name.nil?
        lower_judge_name = content[/(?<=#{Regexp.escape(lower_court_name)}).+?(?=COUNSEL|\Z)/m]
        lower_judge_name = lower_judge_name[..150].split("\n").find { |s| s.match?(/(Judges?|Honorable)/) }[/(?<=Judge|Judges|Honorable).+/].delete_prefix('s').strip rescue nil if lower_judge_name  
      end
    end
    lower_judge_name = lower_judge_name&.empty? ? nil : lower_judge_name 

    party_array = []

    if case_type == 'v' 
      regexp_party_types_without_i = Regexp.new(regexp_party_types.to_s.sub(/\?.*?\:/, ''))
      party_not_lawyer = get_block_not_lawyer(content, regexp_party_types_without_i, lower_court_match)
      party_not_lawyer_desciption = party_not_lawyer
      while true
        content_not_lawyers = party_not_lawyer.strip.match(/(?<parties>.+?)(?=(?<type>(\n{1,3}|,)[^\n]+?#{regexp_party_types_without_i}[^\(\)]*?(,|\.|and|AND|vs?\.)))/m) rescue nil
        break if content_not_lawyers.nil? || content_not_lawyers[:type].match?(/for/i)
        parties = content_not_lawyers[:parties]
        party_type = content_not_lawyers[:type]
        party_array << [party_type, parties]   
        last_index = party_not_lawyer.index(/#{Regexp.escape(party_type)}/m) + party_type.size  
        party_not_lawyer = party_not_lawyer[last_index..].strip[/[^a-z\s\.,:;-].+/m] rescue nil
      end if party_not_lawyer                      
    end
    party_data = clean_party_data(party_array).map { |hash| mark_empty_as_nil(hash.merge(party_description: party_not_lawyer_desciption)) }

    lawyers_data = [] 

    if content.match?(/\n ?COUNSEL ?\n/)
      lawyers_block = content[/(?<=\sCOUNSEL).+?(?=JUDGES?\n{1,2})/m]
      lawyers_description = lawyers_block
      last_new_line = lawyers_block.rindex("\n")
      lawyers_block = lawyers_block.insert(last_new_line, "\n\n")
      lawyers_block = lawyers_block.strip.scan(/.+?(?:For|for|Pro Se)?\n? ?(?:#{regexp_party_types}).*?(?:\n{2,}|\Z)/m)

      lawyers_block.each do |main_line|
        check_party_type_at_end = main_line =~ /, ?\n?(For|for|Pro Se)(?!.*(For|for|Pro Se))\n? ?[^,]*?#{regexp_party_types}.*?(\n{2,}|\Z)/m

        unless check_party_type_at_end
          last_el = main_line.squish.sub(/,$/m, '').split(',').last
          check_party_type_at_end = (main_line.rindex(',') + 1) rescue nil if last_el.match?(/#{regexp_party_types}/)
        end
        next unless check_party_type_at_end

        main_line, curr_party_type = main_line[..check_party_type_at_end], main_line[check_party_type_at_end..] if check_party_type_at_end
        main_line = main_line.squish.sub(/^,/, '').sub(/,$/m, '').squish
        party_lines = main_line.scan(/.+?(?:#{all_states.join('|')})/m).map { |el| el.squish.sub(/^,/, '').sub(/,$/m, '').squish }
        party_lines.each do |line|
          lines = line.split(/,/m)
          curr_state = lines.pop
          curr_city = lines.pop

          data_chunked = lines.chunk_while { |el| !el.match?(/Attorney|Chief|Defender|Assistant|Pro Se/i) }.to_a
          data_chunked.each do |data|  
            party_type = data.last.match?(/Attorney|Chief|Defender|Assistant|Pro Se/i) ? "#{data.pop} #{curr_party_type}" : curr_party_type.to_s
            data.each do |party_name|
              party_name_clean = clean_party_name(party_name)[0]
              next unless party_name_clean
              party_hash = {
                is_lawyer: 1,
                party_name: party_name_clean[..254],
                party_type: clean_party_type(party_type)[..254],
                party_city: curr_city,
                party_state: curr_state,
                party_description: lawyers_description,
              }.merge(@base_details)
              lawyers_data << mark_empty_as_nil(party_hash)
            end
          end
        end
      end
    else
      has_released = content[/Released .{,5} Publication.+?\d{4}\.?/im]
      lower_court_block = content[/(?<=#{lower_court_match.join('|')})[^a-z,]+(?!.+?(#{lower_court_match.join('|')})[^a-z,]+.*\Z)/m]
      check_in_re = content[/(the State of New Mexico|BAR OF NEW MEXICO)(?= ?\n)/m] 
      check_lawyer = content[/(for|For|Pro ?\n?Se)\s?[A-Z][a-z]*?#{regexp_party_types}/m] 
      lawyers_match = has_released || lower_judge_name || lower_court_name || lower_court_block || check_in_re || check_lawyer

      start_lawyers_match = if lawyers_match.nil?
                              nil
                            elsif lawyers_match.match?(/^the State of/)
                              content =~ /the State of New Mexico\s?\n(?!.*?the State of New Mexico\s?\n.*\Z)/m
                            elsif lawyers_match.present?
                              content =~ /#{lawyers_match}/m
                            end

      unless start_lawyers_match.nil? 
        begin
          ending_lawyers_match = content[/#{lawyers_match}.*?\n/m].size
          start_lawyers_block = start_lawyers_match + ending_lawyers_match
          lawyers_block = content[start_lawyers_block..]
          last_new_line = lawyers_block.rindex("\n")
          lawyers_block = lawyers_block.insert(last_new_line, "\n\n")
          lawyers_block = lawyers_block[/.+\n\s?\d{,3}\s?(for|For|Pro ?\n?Se|Guardian)\s?[A-Z][a-z]*?#{regexp_party_types}?s?.*?\n+/m] 
          lawyers_description = lawyers_block

          lawyers_party_types = lawyers_block.scan(/\n+\s?\d{,3}\s?(?:For|for|Pro ?\n?Se|Guardian)\s?[A-Z][a-z]*?(?:#{regexp_party_types})?s?.*?(?:\n{2,}|\Z)/m) rescue []
          lawyers_hash = {}
          lawyers_party_types.each do |type|
            lawyers_hash[type.squish] = lawyers_block[/.+?(?=#{Regexp.escape(type)})/m] 
            lawyers_block = lawyers_block[/(?<=#{Regexp.escape(type)}).*/m]
          end

          lawyers_data = get_lawyers_data(lawyers_hash, regexp_find_limit, lawyers_description) if lawyers_block
        rescue => e
        Hamster.logger.info("project-#{Hamster::project_number} #{@base_details[:case_id]}: Information about lawyers not found!")
        end
      end
    end

    additional_info_arr = []

    lower_court_name = nil if lower_court_name == 'CERTIORARI'

    if @lower_data.is_a?(Array)
      @lower_data.each do |lower_case_id|
        additional_info_arr << {
          lower_court_name: lower_court_name,
          lower_judge_name: lower_judge_name,
          lower_case_id: lower_case_id
        }
      end
    elsif @lower_data.is_a?(Hash)
      @lower_data.each do |lower_link, lower_data|
        lower_data[:case_ids].each do |lower_case_id|
          additional_info_arr << {
            lower_court_name: lower_court_name,
            lower_judge_name: lower_judge_name,
            lower_case_id: lower_case_id,
            lower_link: lower_link
          }
        end
      end
    else
      additional_info_arr << {
        lower_court_name: lower_court_name,
        lower_judge_name: lower_judge_name
      }
    end
    
    additional_info_arr.map! { |hash| mark_empty_as_nil(hash.merge(@base_details)) }

    {
      additional_info: additional_info_arr,
      case_party_lawyer: lawyers_data,
      case_party_not_lawyer: party_data,
      activity_desc: raw_content.squeeze(' ')
    }
  end

  def case_info
    if @lower_data.is_a?(Array)
      lower_case_ids = @lower_data.join('; ')
    elsif @lower_data.is_a?(Hash)
      lower_case_ids = @lower_data.map { |arr| arr.last[:case_ids].join('; ') }.join('; ')
      lower_court_ids = @lower_data.map { |arr| arr.last[:court_id] }.compact.first if @base_details[:court_id] == 332
    end

    info_hash = {
      case_name: case_name,
      case_filed_date: '0000-00-00',
      status_as_of_date: 'has opinion',
      judge_name: all_info_hash['judge_name'],
      lower_court_id: lower_court_ids,
      lower_case_id: lower_case_ids,
      data_source_url: @source_url
    }.merge(@base_details)

    mark_empty_as_nil(info_hash)
  end
  
  def case_activities(description)
    return {} unless find_pdf_link
    pdf_link = "#{Scraper::ORIGIN}#{find_pdf_link}"
    activity_date = format_date(@all_info_hash['activity_date'].squish) rescue nil
    activity_type = @all_info_hash['activity_type'].squish rescue nil
    activities_hash = {
      activity_date: activity_date,
      activity_desc: description,
      activity_type: activity_type,
      file: pdf_link
    }.merge(@base_details)

    activities_hash
  end

  private

  attr_reader :html, :case_id, :case_name

  def scan_available_info
    tr_list = html.css("div.metadata table tr")
    if !tr_list.empty?
      info = tr_list.map do |tr|
        label = tr.at_css("td.label").text.squish
        value = tr.at_css("td.metadata").text.squish rescue nil
        [label, value]
      end.compact
    else
      elements_li = html.css("ul[class='list-group list-group-flush'] li")
      info = elements_li.map do |li|
        key = li.at_css("div[class*='label']").text.squish rescue nil
        value = li.at_css("div:last-child").text.squish rescue nil
        [key, value] if key && value
      end.compact unless elements_li.empty?
    end

    info.to_h.transform_keys { |key| COLUMNS_ALIAS[key] || key }
  rescue
    return nil
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : ((value.to_s.valid_encoding?)? value.to_s.squish : value.to_s.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '').squish)}
  end

  def format_date(value)
    date = value.split("/")
    month = date.shift
    day = date.shift
    Date.parse("#{date[0]}-#{month}-#{day}").strftime("%Y-%m-%d")
  rescue
    nil
  end

  def check_case_name
    case_name = html.at_css("div.metadata h3.title").text.squish rescue nil
    case_name || all_info_hash['case_name'] rescue nil
  end

  def clean_lower_court_name(line)
    name = line.strip.sub(/\s[A-ZÑ]$/, '').sub(/COUNSEL$/, '').sub(/^ON /, '').strip.sub(/^[A-Z]$/, '').sub(/^FROM /i, '').sub(/\\$/, '').sub(/\\$/, '').sub(/^\\$/, '')
    name = 'CERTIORARI' if name.include?('CERTIORARI')
    name.empty? ? nil : name
  rescue
    nil
  end

  def get_lawyers_data(lawyers_block, regexp, description)
    wrong_names = /[Dd]ocket|(?i:consolidate)|Certiorari Granted|[jJ]udge|N[Oo][\.:]|^v\.$/m
    curr_adress = nil
    lawyers_array = []

    lawyers_block.each do |type, lines|
      lines.split("\n").map(&:squish).reject { |el| el.empty? }.reverse.each do |line|
        next if line.match?(/#{regexp}/)
        if line.match? /.+, (#{all_states.join('|')}|New Mexico|D\.C\.?|N\.M\.?)$/
          curr_adress = line
          next
        else
          party_name = clean_party_name(line)[0]
          next if party_name.nil? || party_name.match?(wrong_names)
          adress = curr_adress.sub(/^\d+/, '').strip.match(/(?<city>.+), ?(?<state>([A-Z]{2}|New Mexico||D\.C\.?|N\.M\.?))$/)
          hash = {
            is_lawyer: 1,
            party_name: party_name[..254],
            party_type: type.sub(/^\d+/, '').strip[..254],
            party_city: adress[:city].strip[..254],
            party_state: adress[:state].strip[..254],
            party_description: description
          }.merge(@base_details)
          lawyers_array << mark_empty_as_nil(hash)
        end
      end
    end

    lawyers_array
  end

  def clean_party_data(data)
    clean_data = []
    data.each do |arr|
      parties = arr[1].split(/(?<=[A-Z]|,)\n{,3} ?and(\n| )|\.,(?=\s?[A-Z])|;|(?: AND| and|,)(\n| ).*?(?=[A-Z]{3,})(?!(INC|LLC))|(,?\n|and )Senator|(,?\n|and )Representative|(?<=County Clerk),?\n|, ?\n*? ?(?=Commissioner)/)
      party_type = clean_party_type(arr[0])
      parties = clean_party_name(parties)
      parties.each { |party_name| clean_data <<  mark_empty_as_nil({is_lawyer: 0, party_name: party_name, party_type: party_type}.merge(@base_details)) }
    end

    clean_data
  end

  def clean_party_name(parties)
    wrong_names = /APPEALS FROM|APPEAL FROM|ORIGINAL PROCEEDING|ORIGINAL PROCEEDINGS|CERTIFICATION FROM|INTERLOCUTORY APPEAL FROM|DISCIPLINARY PROCEEDING|PROCEEDINGS|INTERLOCUTORY APPEAL|ADMINISTRATIVE/
    parties = [parties] unless parties.is_a? Array
    parties.map do |row|
      row = row.gsub("v.", '').squish.sub(/^[\d ]+/, '').sub(/^(AND|and)/, '').sub(/(and|AND)$/, '').strip.sub(/[\.,]$/, '').sub(/^[\.,]/, '').sub(/^[\d ]+/, '').sub(/^vs\. ?/, '').strip.sub(/^(AND|and|And)/, '').sub(/(and|AND|And)$/, '').strip[..254]
      row = row.sub(/\(consolidate.+?\)/im, '').sub(/ ?consolidated? ?/im, '').sub(/(S|A)-\d-(SC|CA)-\d+/, '').strip
      row = row.sub(/^(\)|,|\.|&|)/, '').strip.sub(/_+/, '').sub('(License Suspended)', '').strip
      row.blank? || row.match?(wrong_names) || row.match?(/^(F|f)or(\n|\s)/) ? nil : row
    end.compact
  end

  def clean_party_type(row)
    row.squish.tr(",.", '').squish.sub(/^[\d ]+/, '').sub(/^(AND|and)/, '').sub(/^[\d ]+/, '').sub(/^vs\. ?/, '').sub(/^(and|AND)/, '').sub(/(and|AND)$/, '').strip[..254]
  end

  def get_block_not_lawyer(raw_content, regexp_party_types, regexp_lower_court)
    if raw_content.match?(/COUNSEL/)
      block_end = raw_content =~ /COURT ?OF|SUPREME ?COURT|COUNSEL/m
      raw_content = raw_content[..block_end]
      raw_content = raw_content.delete_prefix("\n").delete_prefix("\n").delete_prefix("\n")
      content = raw_content[/\n{2,} ?[^a-z]+?(\n|,|and).+?#{regexp_party_types}s?\..*?\n(?!.*?#{regexp_party_types}s?\..*?\Z)/m]
      content = raw_content[/\n{2,} ?[A-Z\.'"“”\-_Ñ\d ]{2,}.*?(\n|,|and).+?#{regexp_party_types}s?\..*?\n(?!.*?#{regexp_party_types}s?\..*?\Z)/m] unless content
    else
      content = raw_content.match(/(?:N[oO]s(\.|\:) ?#{case_id}?.+?\((?i:Consolidated).*?\)( |\n))(?<content>.+?(CONSOLIDATE|N[oO]s?(\.|\:)(\n| )|(#{regexp_party_types})s?\..*?\n(?!.*?#{regexp_party_types}s?\..*?\Z)))/m)[:content] rescue nil
      content ||= raw_content.match(/(?:N[oO]s?(\.|\:) ?#{case_id}?([A-Z\d, -]{,14}&\s?[A-Z\d, -]{4,14})?)(?<content>.+?(APPEALS? FROM|(?i:CONSOLIDATED? ?WITH)|N[oO]s?(\.|\:)(\n| )|(#{regexp_party_types})s?\..*?\n))/m)[:content] rescue nil
      content ||= raw_content.match(/(?:N[oO]s?(\.|\:) ?#{case_id}?)(?<content>.+?(?=#{regexp_lower_court.join('|')}.*?\n|IN THE MATTER))/m)[:content].sub(/\n+\Z/m, ".\n\n\n")
      unnecessary_line = content.match(/\n+?Filing Date.+?\n+/m)
      content = content.sub(unnecessary_line[0], '') if unnecessary_line
    end
    content
  rescue 
    nil
  end

  def check_lower_data
    tr_element = html.css("div.metadata table tr").find { |tr| tr.at_css("td.label").text.squish == 'Case History Alert' rescue nil }
     case_links = []
     tr_element.css("font[face='Arial']").each do |font_el|
       font_el.children.each_entry do |entry| 
         if entry.text.squish.match?(/affects?$/)
          url = entry.next_element&.attr('href') || entry.next_element.at_css('a')&.attr('href')
          case_links << url if url
         elsif entry.name == 'a' && entry.text.match?(/N[oO](\.|\:)(.+$)/m)
          case_links << entry.attr('href')
         end
       end
     end if tr_element

     cases_ids_with_links = case_links.each_with_object({}) do |link, hash| 
      parser = self.class.new(Scraper.new.get_inner_page(link))
      case_ids = parser.all_info_hash['case_ids'].scan(/[A-Z0-9,-\. ]{4,}?(?:,|$)/)
      case_ids = case_ids.map { |case_id| clean_case_id(case_id) }.uniq
       hash[link] = {case_ids: case_ids, court_id: check_court_id(parser.all_info_hash['court_type'])}
     end

     сases_ids_only = tr_element.css("font[face='Arial']").each_with_object([]) { |font_el, hash| hash << clean_case_id(font_el.text[/N[oO](\.|\:)(.+$)/m, 2]) }.compact.uniq if tr_element
     @lower_data = cases_ids_with_links if cases_ids_with_links && !cases_ids_with_links.empty?
     @lower_data ||= сases_ids_only if сases_ids_only && !сases_ids_only.empty?
   end

   def clean_case_id(case_id)
    case_id.squish.sub(/(\.|,|;)$/, '').sub(/^(\.|,|;)/, '').strip rescue nil
   end

   def check_court_id(type)
    return unless type
    return 332 if type.match?(/Supreme/)
    return 488 if type.match?(/Court of Appeals/)
  end

  def all_states
    [
      "AK", "AL", "AR", "AS", "AZ", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "GU", "HI", 
      "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA", "MD", "ME", "MI", "MN", "MO", "MP", 
      "MS", "MT", "NC", "ND", "NE", "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", 
      "PR", "RI", "SC", "SD", "TN", "TX", "UM", "UT", "VA", "VI", "VT", "WA", "WI", "WV", "WY", "New Mexico", "D.C", "N.M"
    ]
  end
end
