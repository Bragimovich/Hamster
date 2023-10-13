# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    super
  end

  def get_outer_body(inner_page)
    doc = Nokogiri::HTML5(inner_page)
    doc.css('tr.body').map { |e| e.css('a')[0]['href'].split("('")[1].split("')")[0] }
  end

  def image_url(data_page)
    doc = Nokogiri::HTML5(data_page)
    doc.css('#largephoto')[0]['src'] rescue nil
  end

  def parse(data, run_id)
    doc  = Nokogiri::HTML5(data)
    name = doc.css('font')[1].text
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
    hash[:number] = get_date(search_key(tags, 'Permanent ID #:'))
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
      start = true if row.text.include? 'Last Name'
      next unless start
      next if row.text.include? 'Last Name'

      hash = {}
      hash[:immate_id] = inmate_id
      hash[:last_name] = row.css('td')[0].text
      hash[:first_name] = row.css('td')[1].text
      hash[:middle_name] = row.css('td')[2].text
      hash[:full_name] = "#{hash[:last_name]} #{hash[:middle_name]} #{hash[:last_name]}".squish
      alias_array << commom_hash(hash, run_id)
    end
    alias_array
  end

  def get_bonds_array(doc, arrest_id, run_id)
    table = doc.css('tr.bodysmall').select { |e| e.text.include? 'Bond Information'}[0].parent

    start = false
    bonds_array = []
    table.css('tr').each do |row|
      start = true if row.text.include? 'Case #'
      next unless start
      next if row.text.include? 'Case #' or row.text.include? 'Grand Total'
      hash = {}
      hash[:arrest_id] = arrest_id
      hash[:bond_type] = row.css('td')[1].text.squish
      hash[:bond_amount] = row.css('td')[2].text.squish
      hash[:paid_status] = row.css('td')[3].text.squish
      bonds_array << commom_hash(hash, run_id)
    end
    bonds_array
  end

  private

  def search_key(tags, key)
    tags.select { |e| e.text.squish == key}[0].next_element.text
  end

  def get_date(date)
    Date.strptime(date,"%m/%d/%Y") rescue nil
  end

  def commom_hash(hash, run_id)
    hash[:md5_hash] = create_md5_hash(hash)
    hash[:run_id] = run_id
    hash[:touched_run_id] = run_id
    hash[:data_source_url] = 'http://www.eccorrections.org/inmatelookup'
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
