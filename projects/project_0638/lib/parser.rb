# frozen_string_literal: true
require_relative '../models/all_states'
require_relative '../models/all_cities'

class Parser < Hamster::Parser
  attr_accessor :case_id, :data_source_url

  def html=(doc)
    @html = Nokogiri::HTML5(doc.force_encoding("utf-8"))
  end

  def pdf_content(raw_content, raw_content_from_img)
    @pdf_content = raw_content.pages.map(&:text).join("\n").squeeze(' ')
    @pdf_content_from_img = raw_content_from_img
    
    scan_pdf
  end

  def base_details
    {court_id: Manager::COURT_ID, case_id: case_id, data_source_url: data_source_url}
  end

  def older_opinions_pages(&block)
    links = @html.css("h2").find { |h2| h2.text.match?(/Older Opinions/) }.css(" + p + ul li a").map { |a| a['href'].gsub(/^\.\./, 'lawcourt') }.uniq rescue []
    links.each { |link| yield link }
  end 

  def list_pdf_names
    @html.css("table.tbstriped tbody td a:first-child").map { |a| a['href'] }
  end

  def scan_pdf
    check_case_id
    find_judge_name
    find_case_name
    find_status_as_of_date
  end

  def case_info
    hash = {
      case_name:         @case_name,
      case_filed_date:   @case_filed_date,
      status_as_of_date: @status_as_of_date&.first(244),
      judge_name:        clean_judge_name
    }.merge(base_details)

    add_md5_hash(mark_empty_as_nil(hash))
  end

  def case_party
    @all_states ||= get_all_states
    @all_cities ||= get_all_cities

    regexp_party_type = Regexp.new(/,(\s|\n)(pro(\n|\s)se|for(?!\s?which)|appell|amicus|curiae|amici)/m)

    party_block = @pdf_content_from_img[/(?<=#{Regexp.escape(@status_from_img)}).+/m] rescue nil

    if party_block && party_block[0..400].match?(regexp_party_type)
      party_block = party_block.split(/\n[\d\s\n\f]{,5}\n/m)
      start_idx = party_block.index { |el| el.match? regexp_party_type }
      party_arr = party_block[start_idx..].select { |el| el.match? regexp_party_type }
    else
      splitted_text = @pdf_content_from_img.last(20000).split(/\n[\d\s\n\f]{,5}\n/m).reverse
      start_idx = splitted_text.index { |el| el.match? regexp_party_type }
      party_arr = splitted_text[start_idx..].take_while { |el| el.match? regexp_party_type }
    end

    data_party = []

    party_arr.each do |party_line|
      party_type_start_idx = party_line.index regexp_party_type
      lawyers_block, parties_block = [party_line[0..party_type_start_idx-1], party_line[party_type_start_idx..-1]].map { |str| side_clean(str) } 
      lawyers = extract_lawyers(lawyers_block)
    
      if parties_block[..30].match?(/pro(\n|\s)se/m) 
        parties = lawyers.map { |el| new_hash = el.dup; new_hash[:is_lawyer] = 0; new_hash }  
      else
        parties = extract_parties(parties_block)
        lawyers = lawyers.map { |h| new_hash = h.dup; new_hash[:party_type] = "Attorney for #{parties.first[:party_type] rescue nil}".squish; new_hash }
      end

      [lawyers, parties].flatten.reject { |el| el[:party_name].match?(/^Esq\.?\Z/i) || el[:party_name].to_s.size < 2 || el[:party_name].match?(/^et al$|^.orally.$|^Esq\.?$|^Office$/i) }.each do |el|
        data_party << add_md5_hash(el.merge(party_description: party_line.to_s))
      end
    end

    data_party  
  end

  def case_activities
    data_arr = []

    block_activities = @pdf_content[/(?<=#{Regexp.escape(@raw_case_id)}).+?(?=((\n|\s|\t))Panel)/m].strip
    @months = Date::MONTHNAMES[1..].join('|')
    arr_activities = block_activities.scan(/.+?(?i:#{@months}).+?(?=\n|$)/m)

    arr_activities.each do |raw|
      file = data_source_url if clean_activity_type(raw)&.match?(/Decided/)
      activity_hash = {
        activity_type: clean_activity_type(raw),
        activity_date: clean_activity_date(raw),
        file:          file
      }.merge(base_details)

      data_arr << mark_empty_as_nil(add_md5_hash(activity_hash))
    end

    @case_filed_date = data_arr.min_by { |hash| hash[:activity_date] }[:activity_date]

    data_arr.each { |hash| yield hash } if block_given?
    data_arr
  end

  def case_aws_hash(pdf_url, aws_link)
    hash = {
      court_id:     Manager::COURT_ID,
      case_id:      case_id,
      source_link:  pdf_url,
      aws_link:     aws_link,
      source_type: 'activity'
    }

    add_md5_hash(hash)
  end

  def case_ids
    @raw_case_id.squish.scan(/[^&]+?(?=&|;|and|,|$)/m).map { |case_id| side_clean(case_id) } rescue []
  end

  def add_md5_hash(hash)
    hash[:md5_hash] = Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
    hash
  end

  private

  def check_case_id
    @raw_case_id = @pdf_content[/\n{1,}Docket:\t?([^\n]+)/m, 1] rescue nil
  end

  def clean_activity_type(raw)
    raw[/.+?(?=(?i:#{@months}))/m].squish.sub(/:$/, '') rescue nil
  end

  def clean_judge_name
    @judge_name[/.+?(?=Majority|Concurrence|Dissent|\n{2,})/m].first(244)
  end

  def clean_activity_date(raw)
    Date.parse(raw[/(?i:#{@months}).+/m].squish) rescue nil
  end

  def clean_lawyer_name(str)
    str = str.strip
    str.match?(/\n/) ? str.split("\n").last : str
  end

  def find_state(arr)
    arr.find { |el| el.squish.match? @all_states }
  end

  def side_clean(str)
    str.strip.sub(/^(\.|,|:|;|and\s|&)/m, '').sub(/(\.|,|:|\sand|;|&)\Z/m, '').strip
  end

  def find_judge_name
    @judge_name = @pdf_content[/(?<=(\n|\s|\t)Panel):?(.+?\n{3,})/m, 2]
  end

  def find_case_name
    @case_name = @pdf_content[/(?<=#{Regexp.escape(@judge_name)}).+?(?=\[¶1\])/m].strip[/.+(?=\n{3,})/m].squish rescue nil
   end

   def extract_parties(line)
    data_arr = []
    return [] if line.squish == 'for'

    type = line[/.*(appellees?|curiae|appellants?|amicus|amici|pro(\n|\s)se).*?(\s|\n)/m] || line.strip[/.+?(\s|\n)/m] rescue nil
    party_names = line[/(?<=#{type ? Regexp.escape(type) : '^'}).+/m].split(/,(?!(?i: ?inc| ?llc))|;|(?<=\n|\s)and(?=\n|\s)/m)
    
    type = type.squish.sub(/^for/m, '')

    party_names.each do |name|
      name = name.gsub(',', '')
      next if name.squish.empty? || name.squish.match?(/^Esq\.?\Z/m)

      hash = {
        is_lawyer:  0,
        party_name: name&.first(244),
        party_type: type
      }.merge(base_details)

      data_arr << mark_empty_as_nil(hash)
    end

    data_arr
  end

  def extract_lawyers(line)
    data_arr = []

    raw_lines = line.split(/(?<=\n|\s)and(?=\n|\s)|;/m).map {|str| side_clean(str) }

    if raw_lines.size == 1
      data = raw_lines.first.split(',').map { |str| side_clean(str) }.reject { |el| el.match?(/Esq\.?\Z/m) }
      name = clean_lawyer_name(data.first)

      if data.size > 2
        state = find_state(data.last(2))
        data.reject! { |el| el.match? state } if state.present?
        city = data.pop
        law_firm = data[1..]
      else
        city = data.find { |el| el.squish.match? @all_cities }
        data.reject! { |el| el.match? city } if city.present?
        law_firm = data[1..]
      end

      law_firm = law_firm.join(', ').squish rescue nil
      data_arr << {
        is_lawyer:      1,
        party_name:     name&.first(244),
        party_state:    state,
        party_city:     city,
        party_law_firm: law_firm&.first(244)
      }.merge(base_details)
    else
      raw_lines.each_with_index do |data, i|
        next if data.squish.empty?
        data = data.split(',').each { |str| side_clean(str) }.reject { |el| el.match?(/Esq\.?\Z/m) }
        name = clean_lawyer_name(data.first)
        
        if data.size > 1
          state_2 = find_state(data.last(2))
          data.reject! { |el| el.match? state_2 } if state_2.present?
          city_2 = data.pop if data[-1].squish.match? @all_cities        
          law_firm_2 = data[1..]
        else
          law_firm_2 = data[1..]
        end

        law_firm_2 = law_firm_2.join(', ').squish rescue nil
        data_arr << {
          is_lawyer:      1,
          party_name:     name&.first(244),
          party_state:    state_2,
          party_city:     city_2,
          party_law_firm: law_firm_2&.first(244)
        }.merge(base_details)
      end
    end

    data_arr.map! { |hash| mark_empty_as_nil(hash) }
  end

   def find_status_as_of_date
    @status_from_img = @pdf_content_from_img.gsub(/\n ?\d*\n{2,}(?! )/, "\n"*5).match(/(The(\n|\t|\s)*?entry(\n|\t|\s)*?is:?(\n|\t|\d|\s){1,})(?<content>.+?\.?)(?=(\n{2,})|\Z|_{3,})/m)[:content] rescue nil
    @status_from_pdf = @pdf_content.gsub(/\n ?\d*\n{3,}(?! )/, "\n"*5).match(/(The(\n|\t|\s)*?entry(\n|\t|\s)*?is:?(\n|\t|\d|\s){1,})(?<content>.+?\.?)(?=(\n{4,})|\Z|_{3,})/m)[:content] rescue nil
    @status_as_of_date = @status_from_pdf || @status_from_img
   end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : ((value.to_s.valid_encoding?)? value.to_s.squish : value.to_s.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '').squish)}
  end

  def get_all_cities
    cities_form_db = AllCities.pluck(:short_name).uniq
    addit_cities = [
      "York", "Augusta", "Bangor", "Lewiston", "Cumberland", "Washington", "Brunswick", "Miami", "Auburn", "Akron", 
      "Saco", "Chicago", "Boston", "Freeport", "Kennebunk", "Brunswick", "Lewiston", "Farmington", "Biddeford", "Alfred", 
      "Portland", "Island Falls", "Rockland", "District of Columbia"
    ]

    cities = (addit_cities + cities_form_db).map { |city| city.gsub(' ', '\s?\n?').sub(/^/, '^').sub(/$/, '$') }
    Regexp.new(/(#{cities.join('|')})/)
  end

  def get_all_states
    states = AllStates.pluck(:short_name, :name).flatten.map { |state| state.gsub(' ', '\s?\n?').sub(/^/, '^').sub(/$/, '$') }
    Regexp.new(/(#{states.join('|')})/)
  end
end
