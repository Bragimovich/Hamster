class Parser < Hamster::Parser

  BASE_URL = "https://coms.doc.state.mn.us/publicviewer/OffenderDetails/Index/%s/Search"

  def parse_page(response)
    Nokogiri::HTML(response.to_s.force_encoding('UTF-8'))
  end

  def get_token(document)
    document.css('#form1 input')[0]['value']
  end

  def parse_inner_page(html_page)
    response = inner_page(html_page.body)
    href = response.css("#CaseWorker a")[0]["href"] rescue nil
  end

  def parse_data(html_page, contact_number)
    minnesota_hash = {}
    data = inner_page(html_page)
    contact_number = inner_page(contact_number) unless contact_number.nil?
    minnesota_hash[:inmate]             = get_inmates(data)
    minnesota_hash[:mugshot]            = get_mugshots(data)
    minnesota_hash[:inmate_id]          = get_inmate_id(data)
    minnesota_hash[:additional_info]    = get_additional_info(data)
    minnesota_hash[:status]             = get_statuses(data)
    minnesota_hash[:arrest]             = get_arrests(data)
    minnesota_hash[:arrest_additional]  = get_arrests_additional(data, contact_number)
    minnesota_hash[:charges]            = get_charges(data)
    minnesota_hash[:court_hearings]     = get_court_hearings(data)
    minnesota_hash[:holding_facilities] = get_holding_facilities(data)
    minnesota_hash
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def inner_page(inner_page)
    Nokogiri::HTML(inner_page.force_encoding("utf-8"))
  end

  private

  def get_inmates(data)
    inmates = {}
    inmates[:full_name] = data.css("#LastName").text.squish
    inmates[:birthdate] = get_format_date(data.css("#DOB").text.squish)
    inmates[:data_source_url] = get_link(data)
    inmates
  end

  def get_mugshots(data)
    mugshots = {}
    no_photo_string = "oAAAAAAAADYEAAAoAAAAyAAAAMgAAAABAAgAAAAAAECcAADEDgAAxA4AAAAAAAAAAAAAAAAAAICAgAAAAIAAAICAAACAAACAgAAAgAAAAIAAgABAgIAAQEAAAP+AAACAQAAA"
    image_link = data.css('img[title="Mugshot Front"]')[0]['src']
    unless image_link.include? no_photo_string
      mugshots[:original_link] = data.css('img[title="Mugshot Front"]')[0]['src']
      mugshots[:data_source_url] = get_link(data)
    end
    mugshots
  end

  def get_inmate_id(data)
    inmate_id = {}
    inmate_id[:number] = data.css("#OID").text.squish
    inmate_id[:type] = data.css('span[for="OID"]').text.gsub(':','').squish
    inmate_id[:data_source_url] = get_link(data)
    inmate_id
  end

  def get_additional_info(data)
    additional_info = {}
    additional_info[:current_location] = get_current_status(data, "current_location")
    additional_info[:current_status] = data.css("#OffenderStatus").text.squish
    additional_info
  end

  def get_statuses(data)
    statuses = {}
    statuses[:current_status] = data.css("#OffenderStatus").text.squish
    statuses[:status] = get_current_status(data, "status")
    statuses[:date_of_status_change] = get_format_date(get_current_status(data, "date_of_status_change"))
    statuses[:data_source_url] = get_link(data)
    statuses
  end

  def get_arrests(data)
    arrests = {}
    arrests[:current_status] = data.css("#OffenderStatus").text.squish
    arrests[:status] = get_current_status(data, "status")
    arrests[:officer] = get_case_worker(data, "officer")
    arrests[:data_source_url] = get_link(data)
    arrests
  end

  def get_arrests_additional(data, contact_number)
    arrests_additional = {}
    contact_value = get_case_worker(data, "value")
    unless contact_value.nil?
      arrests_additional[:value] = contact_value
      arrests_additional[:key] = "office_phone"
      arrests_additional[:data_source_url] = get_link(data)
    end
    unless contact_number.nil?
      arrests_additional = {}
      arrests_additional = get_phone_number(contact_number, get_link(data))
    end
    arrests_additional
  end

  def get_phone_number(contact_number, link)
    keys = contact_number.css('span[for="OID"]').map { |e| e.text.downcase.strip }
    values = contact_number.css('span[id="OID"]').map { |e| e.text.downcase.strip }
    hash = keys.zip(values).to_h
    result = []
    result << { key: "office_phone", value: hash["office phone:"], data_source_url: link } unless hash["office phone:"].to_s.empty?
    result << { key: "mobile_phone", value: hash["mobile phone:"], data_source_url: link } unless hash["mobile phone:"].to_s.empty?
    result << { key: "fax", value: hash["fax:"], data_source_url: link } unless hash["fax:"].to_s.empty?
    result
  end

  def get_charges(data)
    charges = {}
    charges[:offense_type] = data.css('.row div span[class="fullWidth"]').text.squish
    charges[:data_source_url] = get_link(data)
    charges
  end

  def get_court_hearings(data)
    court_hearings = {}
    court_hearings[:court_date] = get_format_date(data.css("#SentenceDate").text.squish)
    case_numbers = get_case_numbers(data)
    court_hearings[:min_release_date] = get_format_date(data.css("#ReleaseDate").text.squish)
    court_hearings[:max_release_date] = get_format_date(data.css("#ExpirationDate").text.squish)
    court_hearings[:data_source_url] = get_link(data)
    court_hearings_array = case_numbers.map { |case_number| court_hearings.merge(case_number: case_number) }
    court_hearings_array
  end

  def get_holding_facilities(data)
    holding_facilities = {}
    holding_facilities[:current_status] = data.css("#OffenderStatus").text.squish
    holding_facilities[:max_release_date] = get_format_date(data.css("#ExpirationDate").text.squish)
    holding_facilities[:planned_release_date] = get_format_date(data.css("#ReleaseDate").text.squish)
    holding_facilities[:facility] = get_current_status(data, "current_location")
    holding_facilities[:data_source_url] = get_link(data)
    if holding_facilities[:max_release_date].nil? and holding_facilities[:planned_release_date].nil? and holding_facilities[:facility].nil?
      holding_facilities = {}
    end
    holding_facilities
  end

  def get_link(data)
    oid = data.css("#OID").text.squish
    BASE_URL % oid
  end

  def get_format_date(string_date)
    if string_date.nil? || string_date.empty? || !string_date.match?(/^\d{2}\/\d{2}\/\d{4}$/)
      string_date = nil
    else
      input_format = "%m/%d/%Y" 
      output_format = "%Y-%m-%d"
      string_date = Date.strptime(string_date, input_format).strftime(output_format)   
    end
  end

  def get_current_status(data, title)
    complete_value = data.css("#OffenderStatus").text.squish
    split_value = complete_value.split("as of")
    value = nil
    if split_value.length == 1 and title == "status"
      value = get_single_line_status(split_value)
    elsif split_value.length == 1 and title == "current_location"
      value = get_single_line_current_location(split_value)
    elsif split_value.length > 1
      value = get_all_titles(split_value, title)
    end
    value
  end

  def get_single_line_status(value_array)
    status_value = value_array.first
    value = nil
    if status_value.include? "Contact DOC"
      value = "Please Contact DOC Records"
    elsif status_value.include? "Pending admittance"
      value = "Pending Admittance"
    elsif status_value.include? "Civil Commit"
      value = "Civil Commit"
    else
      value = status_value.squish
    end
    value
  end

  def get_single_line_current_location(value_array)
    location_value = value_array.first
    value = nil
    if location_value.include? "Pending admittance"
      value = location_value.split('into a').last.strip.gsub('.', '')
    elsif location_value.include? "Civil Commit"
      value = location_value.split('by').last.strip.gsub('.', '')
    end
    value
  end

  def get_all_titles(split_value, title)
    date_location = split_value.last.split('.')
    value = nil
    if title == "status"
      value = split_value.first.gsub('Assigned to', '').squish
    elsif title == "date_of_status_change"
      value = date_location.first.strip
    elsif title == "current_location" and date_location.length > 1
      value = date_location[1..-1].join(' ').strip.split(/Currently (at|with|in) /).last.gsub(/\ba(?:n)?\b/, '').squish
    end
    value
  end
    
  def get_case_worker(data, title)
    case_worker = data.css("#CaseWorker").text.squish
    case_worker_split = case_worker.split(/(?=\d)/, 2).map(&:strip)
    case title
    when "officer"
      case_worker_split.first
    when "value"
      case_worker_split.length > 1 ? case_worker_split.last : nil
    end
  end

  def get_case_numbers(data)
    case_numbers = data.css("#CourtFileNumbers span")
    case_array = []
    case_numbers.each do |case_number|
      case_array << case_number.text.squish
    end
    case_array
  end
  
end
