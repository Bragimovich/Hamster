class Parser < Hamster::Parser

  def parsing_html(page_html)
    Nokogiri::HTML(page_html.force_encoding('utf-8'))
  end

  def get_links(parsed_page)
    parsed_page.css("tr td a").map{|a| "https://gtlinterface.bernco.gov" +a["href"]}.uniq
  end

  def link_md5(link)
    Digest::MD5.hexdigest(link)
  end

  def get_inmates(document, run_id, link)
    name  = document.css("div.card-header a").text.squish
    age = get_name_table_info(document, "YOB:")
    data_hash = {}
    data_hash[:full_name] = name
    data_hash[:first_name], data_hash[:last_name], data_hash[:middle_name] = name_split(name)
    data_hash[:age]       = age.split("Age").last.gsub(")",'').strip
    data_hash[:birthdate] = Date.parse("01-01-#{age.split.first}") rescue nil
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_inmate_ids(document, inmate_id, run_id, link)
    data_hash = {}
    data_hash[:number]    = get_name_table_info(document, "Person ID:")
    data_hash[:inmate_id] = inmate_id
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_arrest_data(document, inmate_id, run_id, link)
    data_hash = {}
    data_hash[:booking_number] = get_name_table_info(document, "Booking #:")
    data_hash[:booking_date]   = DateTime.strptime(get_name_table_info(document, "Booking Date:"), '%m/%d/%Y').to_date
    data_hash[:arrest_date]    = DateTime.strptime(get_admission_table_info(document, "Admission Date:"), '%m/%d/%Y').to_date
    data_hash[:inmate_id] = inmate_id
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_inmate_ids_additional_data(document, inmate_ids_id, run_id, link)
    hash_array = []
    ["YOB", "Housing"].each do |key|
      data_hash = {}
      data_hash[:key] = key
      data_hash[:value] = (key == 'YOB') ? get_name_table_info(document, "#{key}:").split("(").first.squish : get_name_table_info(document, "#{key}:")
      data_hash[:inmate_ids_id] = inmate_ids_id
      data_hash = mark_empty_as_nil(data_hash)
      hash_array << data_hash.merge!(get_common(data_hash, run_id, link))
    end
    hash_array
  end

  def get_charges_data(document, arrest_id, run_id, link)
    hash_array = []
    charges = get_table(document, "Warrants")
    extra_charges = get_table(document, "Charges")
    unless charges.nil?
      charges.each do |charge|
        hash_array << charge_data(charge, arrest_id, run_id, link)
      end
    end
    unless extra_charges.nil?
      extra_charges.each do |charge|
        hash_array << charge_data(charge, arrest_id, run_id, link, false)
      end
    end
    hash_array
  end

  def get_bond_data(document, arrest_id)
    data_array = []
    bonds = get_table(document, "Bail")
    return nil if bonds.nil?
    bonds.each do |bond|
      next if bond.text.squish.empty?

      data_hash = {}
      bond = clean_row(bond)
      data_hash[:arrest_id] = arrest_id
      data_hash[:number]    = bond[0]
      data_hash[:bond_type] = bond[1]
      data_hash[:bond_fees] = bond[2]
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array
  end

  def get_mugshot_data(aws_link, run_id, inmate_id, link)
    data_hash = {}
    data_hash[:inmate_id]         = inmate_id
    data_hash[:aws_link]          = aws_link
    data_hash[:original_link]     = link
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def get_court_hearings_data(document)
    hash_array = []
    court_hearing = get_table(document, "Charges")
    return nil if court_hearing.nil?
    court_hearing.each do |charge|
      charge = clean_row(charge)
      data_hash = {}
      data_hash[:case_number]   = charge[0]
      data_hash[:sentence_type] = charge[3]
      data_hash[:case_type]     = charge[1]
      data_hash = mark_empty_as_nil(data_hash)
      hash_array << data_hash
    end
    hash_array
  end

  def get_inmate_addresses_data(document, inmate_id, run_id, link)
    data_array = []
    addresses_data = get_table(document, "Arrests")
    addresses_data.css("tr").each do |address|
      data_hash = {}
      address = clean_row(address)
      next if (address.last.empty?) || (address.last.squish == ",")

      data_hash[:location]    = address.last
      data_hash[:arrest_date] = DateTime.strptime(address[2], '%m/%d/%Y').to_date rescue nil
      data_hash[:inmate_id]   = inmate_id
      data_hash = mark_empty_as_nil(data_hash)
      data_hash.merge!(get_common(data_hash, run_id, link))
      data_array << data_hash
    end
    data_array
  end

  def get_mugshot_link(document)
    img_link = document.css("div.col-md-3 img")[0]['src']
    img_link = img_link.split(",").last
    Base64.decode64(img_link)
  end

  def add_charge_id(charge_id, bond, run_id, link)
    bond[:charge_id] = charge_id
    bond.merge!(get_common(bond, run_id, link))
    bond
  end

  private

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "null") ? nil : value}
  end

  def clean_row(row)
    row.text.split("\r\n").reject{|a| a.empty?}.map{|a| a.squish}
  end

  def get_table(document, key)
    document.css("div.w-100").select{|a| a.text.include? key}[0].next_sibling.next_sibling.css("tr")[1..-1] rescue nil
  end

  def get_common(hash, run_id, link)
    {
      md5_hash:            create_md5_hash(hash),
      data_source_url:     link,
      run_id:              run_id,
      touched_run_id:      run_id
    }
  end

  def get_name_table_info(document, key)
    document.css("div.col-md-6 dt.col-sm-4").select{|a|a.text.include? key}[0].next_sibling.next_sibling.text.squish
  end

  def get_admission_table_info(document, key)
    document.css("div.col-md-6 dt.col-sm-6").select{|a|a.text.include? key}[0].next_sibling.next_sibling.text.squish
  end

  def charge_data(charge, arrest_id, run_id, link, flag = true)
    charge = clean_row(charge)
    data_hash = {}
    data_hash[:number]       = charge[0]
    data_hash[:description]  = (flag == true) ? charge[2] : charge[4].gsub(/\\|"/, "")
    data_hash[:offense_type] = charge[1]
    data_hash[:arrest_id] = arrest_id
    data_hash = mark_empty_as_nil(data_hash)
    data_hash.merge!(get_common(data_hash, run_id, link))
    data_hash
  end

  def name_split(name)
    last_name,first_name,middle_name = nil
    return [] if name == nil or name == ','
    last_name,first_name = name.split(",")
    if first_name.split(" ").count == 2
      first_name,middle_name = first_name.split(" ")
    else last_name.split(" ").count == 2
      last_name,middle_name = last_name.split(" ")
    end
    [first_name.strip, last_name, middle_name]
  end
  
  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
