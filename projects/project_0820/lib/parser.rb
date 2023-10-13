
class Parser < Hamster::Parser
    
  def get_main_page_cookie(response)
    cookie_separator(response["set-cookie"])
  end

  def cookie_separator(cookie)
    cookie.split.select { |element| element.length > 15 }.join(" ");
  end

  def get_payload_ids(response)
    doc = Nokogiri::HTML(response.body)
    doc.css("a.underlined").map { |e| e["href"].scan(/\('(\d+)','(\d+)'\)/).flatten }
  end

  def parse(data, run_id)
    doc  = Nokogiri::HTML5(data)
    name = doc.css('font')[1].text rescue nil
    return [nil, nil] if name.nil?

    tags = doc.css('td')
    inmate_hash = get_inmates(tags, name, run_id)
    [inmate_hash, tags]
  end

  def get_holding_facilities_addresses(tags, run_id)
    hash = {}
    hash[:county] = search_key(tags, 'County:')
    commom_hash(hash, run_id)
  end

  def mugshot_hash(image_url, aws_url, inmate_id, run_id)
    hash = {}
    hash[:immate_id] = inmate_id
    hash[:aws_link] = aws_url
    hash[:original_link] = "http://www.eccorrections.org/#{image_url}"
    commom_hash(hash, run_id)
  end

  def  get_holding_facilities(tags, arrest_id, hold_fac_add_id, run_id)
    hash = {}
    hash[:holding_facilities_addresse_id] = hold_fac_add_id
    hash[:arrest_id] = arrest_id
    hash[:facility] = search_key(tags, 'Current Location:')
    hash[:start_date] = get_date(search_key(tags, 'Commitment Date:'))
    hash[:planned_release_date] = get_date(search_key(tags, 'Projected Release Date:'))
    commom_hash(hash, run_id)
  end

  def get_arrests(tags, inmate_id, run_id)
    hash = {}
    hash[:inmate_id] = inmate_id
    hash[:booking_number] = search_key(tags, 'Booking #:')
    commom_hash(hash, run_id)
  end
  
  def get_inmate_additional_info(tags, inmate_id, run_id)
    hash = {}
    hash[:inmate_id] = inmate_id
    hash[:height] = search_key(tags, 'Height:')
    hash[:weight] = search_key(tags, 'Weight:')
    hash[:hair_color] = search_key(tags, 'Hair Color:')
    hash[:eye_color] = search_key(tags, 'Eye Color:')
    hash[:complexion] = search_key(tags, 'Complexion:')
    hash[:current_location] = search_key(tags, 'Current Location:')
    hash[:hair_length] = search_key(tags, 'Hair Length:')
    hash[:ethnicity] = search_key(tags, 'Ethnicity:')
    hash[:citizen] = search_key(tags, 'Citizen:')
    hash[:marital_status] = search_key(tags, 'Marital Status:')
    commom_hash(hash, run_id)
  end

  def get_inmates(tags, name, run_id)
    hash = {}
    hash[:full_name] = name
    hash[:birthdate] = get_date(search_key(tags, 'DOB:'))
    hash[:sex] = search_key(tags, 'Sex:')
    hash[:race] = search_key(tags, 'Race:')
    commom_hash(hash, run_id)
  end

  def get_inmates_ids(tags, inmate_id, run_id)
    hash = {}
    hash[:inmate_id] = inmate_id
    hash[:number] = search_key(tags, 'SO#:')
    commom_hash(hash, run_id)
  end

  def get_charges_array(doc, arrest_id, run_id)
    table = doc.css('tr.bodysmall').select { |e| e.text.include? 'Charge Information'}[0].parent
    return [] if  table.text.include? 'There is no charge information for this inmate.'

    start = false
    charges_array = []
    table.css('tr').each do |row|
      start = true if row.text.include? 'Case #'
      next unless start
      next if row.text.include? 'Case #'
      hash = {}
      hash[:arrest_id] = arrest_id
      hash[:number] = row.css('td')[2].text
      hash[:description] = row.css('td')[3].text
      hash[:docket_number] = row.css('td')[0].text
      charges_array << commom_hash(hash, run_id)
    end
    charges_array
  end

  def get_alias_array(doc, inmate_id, run_id)
    table = doc.css('tr.bodysmall').select { |e| e.text.include? 'Alias Information'}[0].parent
    return [] if  table.text.include? 'There are no aliases for this inmate.'
    
    start = false
    alias_array = []
    table.css('tr').each do |row|
      next if row.text.include? 'Alias Information'

      hash = {}
      hash[:immate_id] = inmate_id
      hash[:full_name] = row.text.squish
      alias_array << commom_hash(hash, run_id)
    end
    alias_array.reject { |e| e[:full_name].empty? }
  end

  def get_bonds_array(doc, arrest_id, run_id)
    table = doc.css('tr.bodysmall').select { |e| e.text.include? 'Bond Information'}[0].parent

    start = false
    bonds_array = []
    table.css('tr').each do |row|
      start = true if row.text.include? 'Case #'
      next unless start
      tags = row.css('td')
      hash = {}
      hash[:arrest_id] = arrest_id
      hash[:made_bond_release_date] =  search_key(tags, 'Post Date:').to_date
      hash[:bond_amount] = search_key(tags, 'Amount:')
      hash[:paid_status] = search_key(tags, 'Status:').squish
      bonds_array << commom_hash(hash, run_id)
    end
    bonds_array
  end

  private

  def search_key(tags, key)
    tags.select { |e| e.text.squish == key}[0].next_element.text rescue nil
  end

  def get_date(date)
    Date.strptime(date,"%m/%d/%Y") rescue nil
  end

  def commom_hash(hash, run_id)
    hash[:md5_hash] = create_md5_hash(hash)
    hash[:run_id] = run_id
    hash[:touched_run_id] = run_id
    hash[:data_source_url] = 'http://iml.slsheriff.org/IML'
    hash
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
