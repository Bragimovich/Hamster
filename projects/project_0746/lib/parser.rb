# frozen_string_literal: true

class Parser < Hamster::Parser

  def get_ids(inner_page)
    doc = Nokogiri::HTML5(inner_page)
    pages = doc.css('.section_data div')[0].text.split.last.gsub('.', '').to_i/50 + 1 rescue 0
    ids = doc.css('table tbody tr')[1..].map { |e| e.css('td')[1].text }
    [ids, pages]
  end

  def get_data(file, run_id)
    @run_id = run_id
    array = ['Name:', 'Age:', 'Ethnicity:', 'Gender:', 'Hair Color:', 'Eye Color:', 'Height:', 'Weight:']
    hash = {}
    doc = Nokogiri::HTML5(file)
    data_headers = doc.css('td.section_data_hdr')
    array = data_headers.map { |e| e.text.squish }
    data_headers.each do |header|
      hash = search_data(header, hash, array)
    end
    inmates_hash            = get_inmates_hash(hash, run_id)
    inmates_additional_hash = get_inmates_additional_hash(hash)
    holding_facilities_hash = get_holding_facilities(hash)
    court_hearings_hash, charges_hash = get_court_hearings_and_charges(hash, doc)
    inmate_ids_hash         = get_inmate_ids(hash)
    mugshots_hash           = get_mugshots(doc)
    [inmates_hash, charges_hash, inmates_additional_hash, holding_facilities_hash, court_hearings_hash, inmate_ids_hash, mugshots_hash]
  end

  def get_arrest_hash(immate_id, run_id)
    data_hash = {}
    data_hash[:immate_id] = immate_id
    data_hash = commom_hash(data_hash, run_id)
    data_hash
  end

  def get_inmate_ids(hash)
    data_hash = {}
    data_hash[:number] = hash["DOC Number:"]
    data_hash
  end

  def get_mugshots(doc)
    link =  doc.css('td img')[0]['src'] rescue nil
    return nil if link.nil?
    data_hash = {}
    data_hash[:aws_link] = 'http://www.doc.state.co.us/' + link
    data_hash
  end

  def get_court_hearings_and_charges(hash, doc)
    data_array = []
    court_hearings =  doc.css('tr').select { |e| e.css('td').count == 4 }[0]
    data = court_hearings.css('td') rescue []
    return [] if data.empty?
    hearings_data_hash = {}
    hearings_data_hash[:next_court_date] = hash["Next Parole Hearing Date:"]
    hearings_data_hash[:sentence_lenght] = get_date(hash["Est. Mandatory Release Date:"])
    hearings_data_hash[:court_date] = get_date(data[0].text.squish)
    hearings_data_hash[:court_name] = data[2].text.squish
    hearings_data_hash[:case_type] = data[3].text.squish
    charges_data_hash = {}
    charges_data_hash[:description] = data[1].text.squish
    [hearings_data_hash, charges_data_hash]
    
  end

  def get_holding_facilities(hash)
    data_hash = {}
    data_hash[:actual_release_date] = get_date(hash["Est. Sentence Discharge Date:"])
    data_hash[:facility] = hash["Current Facility Assignment:"]
    data_hash[:planned_release_date] = get_date(hash["Est. Parole Eligibility Date:"])
    data_hash
  end

  def get_date(date)
    Date.strptime(date,"%m/%d/%Y") rescue nil
  end

  def search_data(header, hash, array)
    text = header.text.squish
    index = array.each_index.select{|i| array[i].include? text}[0] rescue nil
    value = header.next_element.text.squish rescue nil
    hash["#{array[index]}"] = value unless index.nil?
    hash
  end

  def get_inmates_hash(hash, run_id)
  inmates_hash = {}
  inmates_hash[:full_name] = hash["Name:"]
  names = get_names(hash["Name:"]) rescue []
  inmates_hash[:first_name], inmates_hash[:middle_name], inmates_hash[:last_name] = names[0], names[1], names[2]
  inmates_hash[:race] = hash["Ethnicity:"]
  sex = hash["Gender:"].downcase == 'male' ? 'M' : 'F'
  inmates_hash[:sex] = sex
  inmates_hash = commom_hash(inmates_hash, run_id)
  inmates_hash
  end

  def get_inmates_additional_hash(hash)
    data_hash = {}
    data_hash[:age] = hash["Age:"]
    data_hash[:hair_color] = hash["Hair Color:"]
    data_hash[:eye_color] = hash["Eye Color:"]
    data_hash[:height] = hash["Height:"]
    data_hash[:weight] = hash["Weight:"]
    data_hash
  end

  def get_names(name)
    return [] if name.nil? or name.empty?
    name = name.split(',')
    last_name = name.delete_at(0) if name.count > 1
    name = name[0].squish.split
    first_name = name.delete_at(0)
    middle_name = name.join
    [first_name, middle_name, last_name]
  end

  def commom_hash(hash, run_id)
    hash[:md5_hash] = create_md5_hash(hash)
    hash[:run_id] = run_id
    hash[:touched_run_id] = run_id
    hash = mark_empty_as_nil(hash)
    hash[:data_source_url] = 'http://www.doc.state.co.us/oss/'
    hash
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{ |value| (value.to_s.empty? || value == 'null') ? nil : value }
  end

end
