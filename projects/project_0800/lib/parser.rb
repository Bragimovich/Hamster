# frozen_string_literal" => true
class Parser < Hamster::Parser

  DOMAIN = "https://www.dpscs.state.md.us/inmate/"

  def parse_html(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def get_page_num(html)
    doc = parse_html(html)
    doc.css("tbody .smallPrint a").select{|a| a.text.include? "Last"}.map{|e| e['href']}[0].split("=").last.to_i
  end

  def get_inner_links(response)
    doc = parse_html(response)
    odd_links = doc.css("tbody .trDataRowOdd td a").map{|e| DOMAIN + e['href']}
    even_links = doc.css("tbody .trDataRowEven td a").map{|e| DOMAIN + e['href']}
    odd_links + even_links
  end

  def get_facility_link(response)
    doc = parse_html(response)
    doc.css("tbody tr a").map{|e| e['href']}[0]
  end

  def parse_inmate_hash(body, run_id)
    doc = parse_html(body)
    headers = fetch_headers(doc)
    values  = fetch_values(doc.css("tbody tr")[9])
    inmate_hash = {}
    inmate_hash[:first_name]     = search_value(headers, values, "First Name")
    inmate_hash[:middle_name]    = (values.count == 4) ? nil : search_value(headers, values, "Middle Name") 
    inmate_hash[:last_name]      = search_value(headers, values, "Last Name")
    full_name = "#{inmate_hash[:first_name]} #{inmate_hash[:middle_name]} #{inmate_hash[:last_name]}"
    inmate_hash[:full_name]      = full_name.squish
    inmate_hash[:birthdate]      = Date.strptime(values.last, '%m/%d/%Y')
    inmate_hash                  = mark_empty_as_nil(inmate_hash)
    inmate_hash[:md5_hash]       = create_md5_hash(inmate_hash) 
    inmate_hash[:run_id]         = run_id
    inmate_hash[:touched_run_id] = run_id
    inmate_hash
  end

  def parse_inmate_ids_hash(body, inmate_id, run_id)
    doc = parse_html(body)
    headers = fetch_headers(doc)
    inmate_ids_hash = {}
    inmate_ids_hash[:inmate_id]      = inmate_id
    value = doc.css("tbody tr")[11].text.squish
    inmate_ids_hash[:number]         = (value.include? "Please") ? nil : value.split.first
    inmate_ids_hash                  = mark_empty_as_nil(inmate_ids_hash)
    inmate_ids_hash[:md5_hash]       = create_md5_hash(inmate_ids_hash) 
    inmate_ids_hash[:run_id]         = run_id
    inmate_ids_hash[:touched_run_id] = run_id
    inmate_ids_hash
  end

  def additional_inmate_hash(html, id, run_id)
    doc = parse_html(html)
    headers = fetch_headers(doc)
    values  = fetch_values(doc.css("tbody tr")[9])
    idx     = headers.find_index("SID*")
    additional_inmate_hash = {}
    additional_inmate_hash[:inmate_ids_id] = id
    additional_inmate_hash[:key]           = headers[idx]
    additional_inmate_hash[:value]         = values[0]
    additional_inmate_hash                 = mark_empty_as_nil(additional_inmate_hash)
    additional_inmate_hash[:md5_hash]      = create_md5_hash(additional_inmate_hash) 
    additional_inmate_hash[:run_id]        = run_id
    additional_inmate_hash[:touched_run_id]= run_id
    additional_inmate_hash
  end

  def parse_facility_data(html, run_id)
    doc = parse_html(html)
    address = doc.css(".mdgov_contentWrapper p").select{|e| (e.text.include? "Address:") || (e.text.include? "Address")}[0].text.squish.split("Go")[0]
    facilty_addresses_hash = {}
    facilty_addresses_hash[:full_address]   = (address.include? ":") ? address.split(":")[1].squish : address.split("Address")[1].squish
    facilty_addresses_hash[:state], facilty_addresses_hash[:zip], facilty_addresses_hash[:street_address]=  split_address(facilty_addresses_hash[:full_address])
    facilty_addresses_hash                  = mark_empty_as_nil(facilty_addresses_hash)
    facilty_addresses_hash[:md5_hash]       = create_md5_hash(facilty_addresses_hash)
    facilty_addresses_hash[:run_id]         = run_id
    facilty_addresses_hash[:touched_run_id] = run_id
    facilty_addresses_hash
  end

  def holding_facilities(html, facility_id, run_id)
    doc = parse_html(html)
    data_hash = {}
    data_hash[:holding_facilities_addresse_id] = facility_id
    data_hash[:facility]       = doc.css("h1").text.squish
    data_hash[:md5_hash]       = create_md5_hash(data_hash)
    data_hash[:run_id]         = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def additional_facilities(id, html, run_id)
    doc = parse_html(html)
    additional_facilities_hash = {}
    additional_facilities_hash[:holding_facilities_id] = id
    additional_facilities_hash[:abbriviation]          = doc.css("#primary_right_col_2 h3").text.split.first
    additional_facilities_hash[:phone]                 = fetch_additional_facilties_values(doc, "Phone")
    additional_facilities_hash[:fax]                   = fetch_additional_facilties_values(doc, "Fax")

    warden = fetch_additional_facilties_values(doc, "Acting Warden:") rescue nil
    additional_facilities_hash[:warden]             = (warden.nil?) ? fetch_additional_facilties_values(doc, "Warden") : warden

    assistant_warden_key = (warden.nil?) ? "Assistant Warden" : "Acting Assistant Warden"
    additional_facilities_hash[:assistant_warden]   = fetch_additional_facilties_values(doc, assistant_warden_key)

    chief_of_security_key  = (warden.nil?) ? "Chief of Security" : "Acting Facility Administrator"
    additional_facilities_hash[:chief_of_security]       =  fetch_additional_facilties_values(doc, chief_of_security_key)

    additional_facilities_hash[:security_level]          = fetch_additional_facilties_values(doc, "Security Levels")
    additional_facilities_hash[:year_oppened]            = fetch_additional_facilties_values(doc, "Year Opened")
    additional_facilities_hash[:md5_hash]                = create_md5_hash(additional_facilities_hash)
    additional_facilities_hash[:run_id]                  = run_id
    additional_facilities_hash[:touched_run_id]          = run_id
    additional_facilities_hash
  end

  private

  def fetch_additional_facilties_values(doc, key)
    values = doc.css("#primary_right_col_2 p")[1..].select{|e| e.text.include? key} rescue nil
    if key == "Acting Warden:"
      value = (values.empty?) ? nil : values[0].text.squish.split(":")[1].squish
    else
      value = (values[0].text.include? ":") ? values[0].text.squish.split(":")[1].squish : values[0].text.squish.split(key)[1].squish rescue nil
    end
    value
  end

  def split_address(address)
    split_address = address.split(",")
    if split_address.count == 2
      street = split_address.first
      state, zip = get_state_zip(split_address[1].squish.split)
    else
      street = split_address[0..1].join.squish
      state, zip = get_state_zip(split_address[2].squish.split)
    end
    [state, zip, street]
  end

  def get_state_zip(name)
    if name.count >= 2
      state = name[0]
      zip = name.last
    else
      state = nil
      zip = name.last
    end
    [state, zip]
  end

  def fetch_values(row)
    row.text.squish.split
  end

  def fetch_headers(doc)
    doc.css("tbody th").map{|e| e.text.squish}
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| (value.to_s == " ") || (value == 'null') || (value == '') ? nil : value }
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end

  def search_value(headers, values, key)
    begin
      idx = headers.find_index(key) 
      values[idx]
    rescue
      nil
    end
  end

end
