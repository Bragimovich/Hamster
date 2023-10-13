class Parser < Hamster::Parser

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def get_inmate_links(search_page)
    search_page.css('table.at-data-table a').map{|e| "https://www1.maine.gov/cgi-bin/online/mdoc/search-and-deposit/" + e['href']}.uniq
  end

  def find_next_page(search_page)
    next_check = search_page.css('a').select{|e| e.text.include?('Next') && e.text.include?('results')}
    next_flag = (next_check.empty?) ? true : false
    next_url = (next_check.empty?) ? nil : next_check.first['href']
    [next_flag, next_url]
  end

  def get_maine_inmates(document, link, run_id)
    table = document.css('table.at-data-table')[0]
    inmitates_data_hash = {}
    inmitates_data_hash[:full_name]             = data_fetcher(table, 'Last Name, First Name, Middle Initial:')
    inmitates_data_hash[:first_name], inmitates_data_hash[:middle_name], inmitates_data_hash[:last_name], inmitates_data_hash[:suffix]  = name_split(inmitates_data_hash[:full_name])
    birthdate                                   = get_date(data_fetcher(table, 'Date of Birth:'))
    inmitates_data_hash[:birthdate]             = birthdate
    inmitates_data_hash[:sex]                   = data_fetcher(table, 'Gender:')
    inmitates_data_hash[:race]                  = data_fetcher(table, 'Race/Ethnicity:')
    inmitates_data_hash = mark_empty_as_nil(inmitates_data_hash)
    inmitates_data_hash.merge!(get_common(inmitates_data_hash, run_id, link))
    inmitates_data_hash
  end

  def get_arrests_data(document, link, run_id, inmate_id)
    table = document.css('table.at-data-table')[0]
    data_hash                         = {}
    data_hash[:inmate_id]             = inmate_id
    data_hash[:status]                = data_fetcher(table, 'Status:')
    data_hash[:officer]               = data_fetcher(table, 'Adult Community Corrections Client Officer:')
    data_hash[:booking_agency]        = data_fetcher(table, 'Location(s) and location phone number(s):')
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_inmate_ids(document, link, run_id, inmate_id)
    table = document.css('table.at-data-table')[0]
    data_hash = {}
    data_hash[:inmate_id] = inmate_id
    data_hash[:number]    = data_fetcher(table, 'MDOC Number:').to_i
    data_hash[:type]      = "MDOC Number"
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_charges(document, link, run_id, arrest_id)
    table = document.css('table.at-data-table')[1]
    loop_count = table.css('tr.at-data-table-title')[1..-1].reject {|a| a.text.include? "Conditions of Supervision"}.count rescue nil
    loop_count == 0 ? nil : loop_count
    data_array = []
    loop_count.times do |i|
      data_hash = {}
      data_hash[:arrest_id]     = arrest_id
      data_hash[:docket_number] = data_fetcher(table, 'Docket Number:', i)
      crime_class_offense_type  = data_fetcher(table, 'Offense (Class):', i)
      data_hash[:offense_type ] = crime_class_offense_type
      data_hash[:crime_class]   = crime_class_offense_type.match(/\((\w)\)/)[1] rescue nil
      data_hash[:count]         = data_fetcher(table, 'Count:', i)
      data_hash.merge!(get_common(data_hash, run_id, link))
      data_array << data_hash
    end
    data_array
  end

  def get_court_hearings(document, link, run_id, charges_ids)
    table = document.css('table.at-data-table')[1]
    data_array = []
    charges_ids.count.times do |i|
      data_hash = {}
      data_hash[:charge_id]         = charges_ids[i]
      data_hash[:court_name]        = data_fetcher(table, 'Court:', i)
      data_hash[:sentence_lenght]   = data_fetcher(table, 'Sentence:', i)
      data_hash.merge!(get_common(data_hash, run_id, link))
      data_array << data_hash
    end
    data_array
  end

  def get_maine_holding_facilities(document, link, run_id, arrest_id)
    table = document.css('table.at-data-table')[1]
    loop_count = table.css('tr.at-data-table-title')[1..-1].reject {|a| a.text.include? "Conditions of Supervision"}.count rescue nil
    data_array = []
    loop_count.times do |i|
      data_hash = {}
      data_hash[:arrest_id]  = arrest_id
      data_hash[:start_date] = DateTime.strptime(data_fetcher(table, 'Sentence Date:', i), '%m/%d/%Y').to_date rescue nil
      data_hash.merge!(get_common(data_hash, run_id, link))
      data_array << data_hash
    end
    data_array
  end

  def maine_mugshots(document, link, run_id, inmate_id, aws_link, image_url)
    data_hash = {}
    data_hash[:inmate_id]         = inmate_id
    data_hash[:aws_link]          = aws_link
    data_hash[:original_link]     = 'https://www1.maine.gov' + image_url
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash]        = create_md5_hash(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_maine_additional_info(document, run_id, inmate_id)
    table = document.css('table.at-data-table')[0]
    data_hash                         = {}
    data_hash[:inmate_id]             = inmate_id
    data_hash[:height]                = data_fetcher(table, 'Height:')
    data_hash[:weight]                = data_fetcher(table, 'Weight (Pounds):')
    data_hash[:hair_color]            = data_fetcher(table, 'Hair Color:')
    data_hash[:eye_color]             = data_fetcher(table, 'Eye Color:')
    data_hash[:age]                   = data_fetcher(table, 'Age (Years):')
    data_hash[:body_modification_raw] = data_fetcher(table, 'Scars, Marks, Tattoos:')
    body_modifications                = data_fetcher(table, 'Scars, Marks, Tattoos:')
    data_hash[:tattoos]               = get_string_Values('Tattoo', body_modifications, ['Scar', 'Mark'])
    data_hash[:scars]                 = get_string_Values('Scar', body_modifications , ['Tattoo', 'Mark'])
    data_hash[:marks]                 = get_string_Values('Mark', body_modifications, ['Tattoo', 'Scar'])
    data_hash[:Other_Physical_Characteristics] = get_string_Values('Other Physical Characteristics', body_modifications, ['Tattoo', 'Scar', 'Mark'])
    data_hash[:Skin_Discolorations]            = get_string_Values('Skin Discolorations (Including Birthmarks)' , body_modifications, ['Tattoo', 'Scar', 'Mark' , 'Other Physical Characteristics'])
    data_hash[:current_location]      = data_fetcher(table, 'Location(s) and location phone number(s):')
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash]              = create_md5_hash(data_hash)
    data_hash[:run_id]                = run_id
    data_hash[:touched_run_id]        = run_id
    data_hash
  end

  def get_maine_statuses(document, link, run_id, inmate_id)
    table = document.css('table.at-data-table')[0]
    data_hash                           = {}
    data_hash[:inmate_id]               = inmate_id
    data_hash[:status]                  = data_fetcher(table, 'Status:')
    data_hash[:date_of_status_change]   = Date.today
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_maine_inmate_aliases(document, link, run_id, inmate_id)
    table = document.css('table.at-data-table')[0]
    count = data_fetcher(table, 'Alias or Aliases:').split(',') rescue nil
    data_array = []
    count.each do |name|
      data_hash                           = {}
      data_hash[:inmate_id]               = inmate_id
      data_hash[:full_name]               = name
      data_hash = mark_empty_as_nil(data_hash)
      data_hash.merge!(get_common(data_hash, run_id, link))
      data_array << data_hash
    end
    data_array
  end

  def check_data(document)
    table = document.css('table.at-data-table')[0]
    data_fetcher(table, 'Last Name, First Name, Middle Initial:') rescue nil
  end

  private

  def get_string_Values(search_string, value, mark_value)
    split_value = value.split(',').map(&:squish)
    all_matched_indexes = split_value.each_with_index.map {|e, index| index if  e == search_string}.compact
    extracted_values = []
    all_matched_indexes.each_with_index do |match_index, index|
      if !split_value[(match_index+2)].nil? and (split_value[(match_index+2)] != mark_value.first and split_value[(match_index+2)] != mark_value.last and split_value[(match_index+2)] != mark_value[1])
        extracted_values << split_value[(match_index+1)..(match_index+2)].reject{|e| e == search_string}.join(', ').squish
      else
        extracted_values << split_value[(match_index+1)].squish
      end
    end
    extracted_values.join('; ')
  end

  def get_common(hash, run_id, link)
    {
      md5_hash:            create_md5_hash(hash),
      data_source_url:     link,
      run_id:              run_id,
      touched_run_id:      run_id
    }
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def name_split(full_name)
    if full_name.include? ' - '
      name_spliting = full_name.strip.split(',').map {|a| a.gsub(' - ', '-')&.strip}
      first_name = name_spliting[0]
      last_name = name_spliting[-1]
      if last_name.split(' ').count == 2
        middle_name, last_name = last_name.split(' ')
      end
    else
      name_spliting = full_name.strip.split(' ') rescue nil
      middle_name, last_name = nil, nil
      first_name  = name_spliting[0] rescue nil
      suffix_name = get_suffix(name_spliting) rescue nil
      filtered_array = name_spliting.reject{|s| s.upcase == "JR" || s.upcase == "JR." || s.upcase == "SR" || s.upcase == "SR."}
      if filtered_array.count == 1
        middle_name = nil
        last_name = nil
      elsif filtered_array.count == 2
        middle_name = nil
        last_name = filtered_array[-1]
      elsif filtered_array.count == 3
        middle_name = filtered_array[1]
        last_name = filtered_array[2]
      elsif filtered_array.count > 3
        middle_name = filtered_array[1]
        last_name = filtered_array[2..-1].join(" ")
      end
    end  
    [remove_comma(first_name), remove_comma(middle_name), remove_comma(last_name), suffix_name]
  end

  def remove_comma(name)
    name.nil? ? name : name.gsub(",", "")
  end

  def get_suffix(name_spliting)
    suffix_value = nil
    if name_spliting.select{|s| s.upcase == "JR" || s.upcase == "JR." || s.upcase == "SR" || s.upcase == "SR."}.count > 0
      suffix_value = name_spliting.select{|s| s.upcase == "JR" || s.upcase == "JR." || s.upcase == "SR" || s.upcase == "SR."}[0]
    end
    suffix_value
  end

  def get_date(date)
    (Date.strptime(date, "%m/%d/%Y")).strftime("%Y-%m-%d") rescue nil
  end

  def charges_data_fetcher(table, search_text, index)
      values = table.css('td').select { |e| e.text.include? search_text }[index]
    unless values.nil?
      values.next_element.text.squish
    else
      nil
    end
  end

  def data_fetcher(table, search_text, index = 0)
    values = table.css('td').select{|e| e.text.include? search_text}[index]
    unless values.nil?
      values.next_element.text.squish
    else
      nil
    end
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.nil? || value.to_s.squish.empty? || value == "null" || value == 0) ? nil : value}
  end
end
