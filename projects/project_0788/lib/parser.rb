class Parser < Hamster::Parser

  def parse_page(response)
    Nokogiri::HTML(response.to_s.force_encoding('UTF-8'))
  end

  def get_values(main)
    event_validation = main.css("#__EVENTVALIDATION")[0]['value']
    view_state = main.css("#__VIEWSTATE")[0]['value']
    generator = main.css("#__VIEWSTATEGENERATOR")[0]['value']
    [event_validation, view_state, generator]
  end

  def get_string_values(document)
    value = document.css('text()').select{|e| e.text.include? "EVENTVALIDATION"}.first.text
    event_validation = search_string(value, '__EVENTVALIDATION')
    view_state = search_string(value, '__VIEWSTATE')
    generator = search_string(value, '__VIEWSTATEGENERATOR')
    [event_validation, view_state, generator]
  end

  def fetch_links(document)
    document.css('#grvwSelections').css('tr')[1..-1].map{|e| e.css('a')[0]['href']}.select{|e| e.include? 'InmateDetail'} rescue []
  end

  def pagination_exists?(document, counter)
    begin
      ((document.css('#grvwSelections').css('tr')[-2]['style'].include? 'DarkGreen') && (document.css('#grvwSelections').css('tr')[-2].text.include? "#{counter}")) ? true : false
    rescue StandardError => e
      (e.full_message.include? 'nil') ? true : false
    end
  end

  def get_inmates_data(document, link, run_id)
    inmitates_data_hash = {}
    inmitates_data_hash[:full_name]             = data_fetcher(document, 'Name:')
    inmitates_data_hash[:first_name], inmitates_data_hash[:middle_name], inmitates_data_hash[:last_name], inmitates_data_hash[:suffix]  = name_split(inmitates_data_hash[:full_name])
    birthdate                                   = get_date(data_fetcher(document, 'DOB:'))
    inmitates_data_hash[:birthdate]             = birthdate
    inmitates_data_hash[:sex]                   = data_fetcher(document, 'Sex:')
    inmitates_data_hash[:race]                  = data_fetcher(document, 'Race:')
    inmitates_data_hash[:hair_color]            = data_fetcher(document, 'Hair:')
    inmitates_data_hash[:height]                = data_fetcher(document, 'Height:')
    inmitates_data_hash[:eye_color]             = data_fetcher(document, 'Eyes:')
    inmitates_data_hash[:weight]                = data_fetcher(document, 'Weight:').to_i
    inmitates_data_hash[:age]                   = data_fetcher(document, 'Age:').to_i
    inmitates_data_hash = mark_empty_as_nil(inmitates_data_hash)
    inmitates_data_hash.merge!(get_common(inmitates_data_hash, run_id, link))
    inmitates_data_hash
  end

  def get_arrests_data(document, link, run_id, immate_id)
    data_hash                         = {}
    data_hash[:immate_id]             = immate_id
    data_hash[:officer]               = data_fetcher(document, 'Officer:')
    data_hash[:status]                = data_fetcher(document, 'Status:')
    data_hash[:booking_number]        = data_fetcher(document, 'BookingNo:')
    data_hash[:actual_booking_number] = data_fetcher(document, 'AgencyCase:')
    arrest_date                       = data_fetcher(document,'ArrestDate:')
    booking_date                      = data_fetcher(document,'BookDate:')
    data_hash[:booking_agency]        = data_fetcher(document,'ArrestingAgency:')
    data_hash[:booking_agency_type]   = data_fetcher(document,'ArrestingAgencyType:')
    data_hash[:booking_agency_subtype]= data_fetcher(document,'ArrestingAgencySubType:')
    arrest_time                       = data_fetcher(document,'ArrestTime:')
    data_hash[:arrest_date]           = get_datetime(arrest_date, arrest_time)
    booking_time                      = data_fetcher(document,'BookTime:')
    data_hash[:booking_date]          = get_datetime(booking_date, booking_time)
    data_hash[:full_address]          = data_fetcher(document,'HousgLocation:')
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_holds(document, link, run_id, arrest_id)
    holdings = document.css("#grvwHolds tr")
    return if holdings.count < 2
    header = holdings[0]
    holdings.shift
    keys = get_table_data("th", header)
    values_array = holdings.map do |tr|
      values = get_table_data("td", tr)
    end
    holds_type = keys.index("Hold Type")
    start_date = keys.index("Start Date")
    removed_date = keys.index("Removed Date")
    data_array = []
    values_array.each do |row|
      holds_hash = {}
      holds_hash[:arrest_id] = arrest_id
      holds_hash[:facility_type]  = row[holds_type]
      holds_hash[:start_date]  = get_date(row[start_date])
      holds_hash[:actual_release_date]  = get_date(row[removed_date])
      planned_release_date = getting_planned_release_date(document)
      holds_hash[:planned_release_date]  = (planned_release_date.nil?) || (planned_release_date.squish.empty?) ? "not attending data" : planned_release_date
      holds_hash = mark_empty_as_nil(holds_hash)
      holds_hash.merge!(get_common(holds_hash, run_id, link))
      data_array << holds_hash
    end
    data_array
  end

  def get_inmate_ids(document, link, run_id, immate_id)
    data_hash = {}
    data_hash[:number] = data_fetcher(document, 'PersonID:').to_i
    data_hash[:immate_id] = immate_id
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_charges_bonds_hearings_data(document, link, run_id, arrest_id)
    charges_array = []
    bonds_array = []
    hearings_array = []
    table_rows = document.css('#grvwCharges tr').count
    return if table_rows < 2
    headers = document.css('#grvwCharges tr th').map{|th| th.text}
    rows_count = table_rows -1
    rows_count > 11 ? rows_count = 10 : rows_count
    (1..rows_count).each do |tr_number|
      keys = headers
      values = document.css('#grvwCharges tr')[tr_number].css('td').map{|td| td.text}
      hash = keys.zip(values).to_h
      charges_hash = charges_hash_fun(hash, run_id, link, arrest_id)
      charges_array << charges_hash
      bonds_hash = bonds_hash_fun(hash, run_id, link, arrest_id)
      bonds_array << bonds_hash
      hearings_hash = hearings_hash_fun(hash, link, run_id)
      hearings_array << hearings_hash
    end
    [charges_array, bonds_array, hearings_array]
  end

  def get_common(hash, run_id, link)
    {
      md5_hash:            create_md5_hash(hash),
      data_source_url:     "https://publicinfo.fresnosheriff.org/InmateInfoV2/#{link}",
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

  private

  def get_table_data(type, row)
    data = row.css(type).map do |row|
      row.text.strip
    end
  end

  def get_datetime(date, time)
    date = time = nil if date.nil?
    return nil if date.nil? || time.nil?
    time =  time.nil? ? "12:00" : time
    formatted_date = date.include?("/") ? DateTime.strptime(date, '%m/%d/%Y').strftime('%Y-%m-%d') : date
    datetime = DateTime.parse("#{formatted_date} #{time}")
    sql_datetime = datetime.strftime('%Y-%m-%d %H:%M:%S')
    sql_datetime
  end

  def get_date(date)
    (Date.strptime(date, "%m/%d/%Y")).strftime("%Y-%m-%d") rescue nil
  end

  def get_suffix(name_spliting)
    suffix_value = nil
    if name_spliting.select{|s| s.upcase == "JR" || s.upcase == "JR." || s.upcase == "SR" || s.upcase == "SR."}.count > 0
      suffix_value = name_spliting.select{|s| s.upcase == "JR" || s.upcase == "JR." || s.upcase == "SR" || s.upcase == "SR."}[0]
    end
    suffix_value
  end


  def name_split(full_name)
    name_spliting = full_name.strip.split(' ')
    middle_name, last_name = nil, nil
    first_name  = name_spliting[0] rescue nil
    suffix_name = get_suffix(name_spliting)
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
    [remove_comma(first_name), remove_comma(middle_name), remove_comma(last_name), suffix_name]
  end

  def remove_comma(name)
    name.nil? ? name : name.gsub(",", "")
  end

  def data_fetcher(document, search_text)
    values = document.css('td[class="Constant"]').select{|e| e.text == search_text}
    unless values.empty?
      values.first.next_element.text.squish
    else
      nil
    end
  end

  def charges_hash_fun(hash, run_id, link, arrest_id)
    charges_hash = {}
    charges_hash[:arrest_id] = arrest_id
    charges_hash[:number] = hash["Charges"]
    charges_hash[:description] = hash["Description"]
    charges_hash[:offense_type] = hash["Level"]
    charges_hash = mark_empty_as_nil(charges_hash)
    charges_hash.merge!(get_common(charges_hash, run_id, link))
    charges_hash
  end

  def bonds_hash_fun(hash, run_id, link, arrest_id)
    bonds_hash = {}
    bonds_hash[:arrest_id] = arrest_id
    bail_amount = hash["Bail Amount"]
    bonds_hash[:bond_amount] = (bail_amount.nil?) || (bail_amount == "###########") ? nil : bail_amount.strip
    bonds_hash[:bond_type] = hash["Authority"]
    bonds_hash[:paid_status] = hash["Bailout"]
    bonds_hash = mark_empty_as_nil(bonds_hash)
    bonds_hash
  end

  def hearings_hash_fun(hash, link, run_id)
    hearings_hash = {}
    hearings_hash[:case_number] = hash["Case No."]
    court_name = hash["Court"]
    hearings_hash[:court_name] = (court_name.nil?) || (court_name.squish.empty?) ? "not attending data" : court_name
    sentence_date = hash["Sentence Date"]
    hearings_hash[:court_date] = (sentence_date.nil?) || (sentence_date.squish.empty?) ? "not attending date" : sentence_date
    sentence_length = hash["Sentence Days"]
    hearings_hash[:sentence_lenght] = (sentence_length.nil?) || (sentence_length.squish.empty?) ? "not attending date" : sentence_length
    hearings_hash
  end

  def getting_planned_release_date(document)
    table_rows = document.css('#grvwCharges tr').count
    return if table_rows < 2
    keys = document.css('#grvwCharges tr th').map{|th| th.text}
    values = document.css('#grvwCharges tr')[1].css('td').map{|td| td.text}
    hash = keys.zip(values).to_h
    hash["Release Date"]
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.nil? || value.to_s.squish.empty? || value == "null" || value == 0) ? nil : value}
  end

  def search_string(value, search_text)
    ind = value.split('|').index search_text
    value.split('|')[ind+1]
  end

end
