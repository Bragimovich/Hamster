class Parser < Hamster::Parser

  def captcha_image_url(response)
    document = parse_page(response.body)
    src = document.css('#captchaImg')[0]['src']
    "https://web.mo.gov#{src}"
  end

  def parse_page(inner_page)
    Nokogiri::HTML(inner_page.force_encoding("utf-8"))
  end

  def get_doc_id(document)
    search("DOC ID",document)
  end

  def get_links(response)
    document = parse_page(response)
    document.css(".listingTable tr a").map{|a| "https://web.mo.gov#{a['href']}" }
  end

  def missouri_inmates(document, run_id)
    data_hash = {}
    full_name = search("Name",document)
    data_hash[:full_name] = full_name
    data_hash = main_table_name_splitting(data_hash, full_name)
    data_hash[:birthdate] = Date.strptime(search("Birth",document),'%m/%d/%Y')
    data_hash[:sex] = search("Sex",document)[0]
    data_hash[:race] = search("Race",document)
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://web.mo.gov/doc/offSearchWeb/"
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def missouri_inmate_ids(document, run_id, inmate_id)
    data_hash = {}
    data_hash[:immate_id] = inmate_id
    data_hash[:number] = search("DOC ID",document)
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://web.mo.gov/doc/offSearchWeb/"
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def mugshot_link(document)
    document.css('.displayTable tr td img')[0]['src']
  end

  def missouri_mugshots(document, link, run_id, inmate_id, aws_link)
    data_hash = {}
    data_hash[:immate_id] = inmate_id
    data_hash[:aws_link] = aws_link
    data_hash[:original_link] = link
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://web.mo.gov/doc/offSearchWeb/"
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def missouri_inmate_additional_info(document, run_id, inmate_id)
    hash_array = []
    ["Height/Weight", "Hair/Eyes"].each do |search_text|
      data = search("#{search_text}",document)
      data = (data.split('/').count > 2) ? [data.split('/')[0..-2].join('/').strip,data.split('/')[-1].strip] : data.split('/')
      data.each_with_index do |data_value, data_index|
        data_hash = {}
        data_hash[:immate_id] = inmate_id
        data_hash[:key] = search_text.split('/')[data_index].strip rescue nil
        data_hash[:value] = data_value.strip rescue nil
        data_hash = mark_empty_as_nil(data_hash)
        data_hash[:md5_hash] = create_md5_hash(data_hash)
        data_hash[:run_id] = run_id
        data_hash[:touched_run_id] = run_id
        hash_array << data_hash
      end
    end
    hash_array
  end

  def missouri_arrests(document, run_id, inmate_id)
    data_hash = {}
    data_hash[:immate_id] = inmate_id
    data_hash[:status] = search("Assigned Location",document)
    data_hash[:officer] = search("Assigned Officer",document)
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://web.mo.gov/doc/offSearchWeb/"
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def missouri_inmate_addresses(document, run_id, inmate_id)
    data_hash = {}
    data_hash[:immate_id] = inmate_id
    full_address = search("Address",document)
    data_hash[:full_address] = full_address
    location = search("Assigned Location",document)
    data_hash = inmate_address_splitting(data_hash, location, full_address)
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://web.mo.gov/doc/offSearchWeb/"
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def missouri_holding_facilities_addresses(document, run_id)
    data_hash = {}
    full_address = search("Address",document)
    data_hash[:full_address] = full_address
    data_hash = facilities_address_splitting(data_hash, full_address)
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def missouri_holding_facilities(document, run_id, arrest_id, holding_facilities_addresses_id)
    data_hash = {}
    data_hash[:arrest_id] = arrest_id
    data_hash[:holding_facilities_addresse_id] = holding_facilities_addresses_id
    data_hash[:facility] = search("Assigned Location",document)
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://web.mo.gov/doc/offSearchWeb/"
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def missouri_charges(document, run_id, arrest_id)
    data_hash = {}
    data_hash[:arrest_id] = arrest_id
    data_hash[:number] = search("DOC ID",document)
    data_hash[:name] = search("Active Offenses",document)
    data_hash[:offense_type] = search("Completed Offenses",document)
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://web.mo.gov/doc/offSearchWeb/"
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def missouri_court_hearings(document, run_id, charge_id)
    data_hash = {}
    data_hash[:charge_id] = charge_id
    data_hash[:sentence_lenght] = search("Sentence Summary",document)
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://web.mo.gov/doc/offSearchWeb/"
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def missouri_inmate_aliases(document, run_id, inmate_id)
    data_array = []
    all_aliases = search("Aliases",document).split("\;")
    all_aliases.each do |aliase|
      data_hash = {}
      data_hash[:immate_id] = inmate_id
      name_parts = aliase.strip.split(/[\s-]+/)
      data_hash[:full_name] = aliase.strip
      next if data_hash[:full_name] == 'Delete' or data_hash[:full_name].nil?

      data_hash = aliase_name_spliting(data_hash, name_parts)
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = "https://web.mo.gov/doc/offSearchWeb/"
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_array << data_hash
    end
    data_array
  end

  private

  def main_table_name_splitting(data_hash, full_name)
    full_name_parts = full_name.split(/[\s-]+/)
    data_hash[:first_name] = full_name_parts[0]
    data_hash[:middle_name] = full_name_parts[1]
    data_hash[:last_name] = full_name_parts[2..-1].join(' ')
    data_hash
  end

  def aliase_name_spliting(data_hash, name_parts)
    if name_parts.length == 3
      data_hash[:first_name] = name_parts[0]
      data_hash[:middle_name] = name_parts[1]
      data_hash[:last_name] = name_parts[2]
    elsif name_parts.length == 2
      data_hash[:first_name] = name_parts[0]
      data_hash[:middle_name] = nil
      data_hash[:last_name] = name_parts[1]
    elsif name_parts.length > 3
      data_hash[:first_name] = name_parts[0]
      data_hash[:middle_name] = name_parts[1]
      data_hash[:last_name] = name_parts[-2..-1].join(' ')
    else
      data_hash[:first_name] = name_parts[0] rescue nil
      data_hash[:middle_name] = nil
      data_hash[:last_name] = nil
    end
    data_hash
  end

  def facilities_address_splitting(data_hash, full_address)
    address_split = full_address.split(',')
    if address_split.empty?
      data_hash[:street_address] = nil
      data_hash[:city] = nil
      data_hash[:state] = nil
      data_hash[:zip] = nil
      return data_hash
    end
    if full_address.count(",") > 2
      data_hash[:street_address] = address_split[0..-3].join(",").strip
      data_hash[:city] = address_split[-2].strip
    else
      data_hash[:street_address] = address_split[0].strip
      data_hash[:city] = address_split[-2].strip
    end
    data_hash[:state] = fetch_state(address_split)
    data_hash[:zip] = fetch_zip(address_split)
    data_hash
  end

  def fetch_state(address_split)
    address_split[-1].split.select{|e| e.size == 2}.first rescue nil
  end

  def fetch_zip(address_split)
    address_split[-1].split.select{|e| e.to_i != 0}.first rescue nil
  end

  def inmate_address_splitting(data_hash, location, full_address)
    if match = location.match(/District\s+(\w+)/)
      data_hash[:unit_number] = "District " + match[1]
    else
      data_hash[:unit_number]  = nil
    end
    data_hash = facilities_address_splitting(data_hash, full_address)
    data_hash
  end

  def search(match_string,document)
    document.css('.displayTable td').each do |td|
      if td.text.strip.include?(match_string)
        return td.next_element.text.squish rescue nil
      end
    end
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "null" || value == " ") ? nil : value}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
