# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    super
    @scraper = Scraper.new
  end

  def add_md5(hash)
    hash['deleted'] = 0
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end
  
  def check_value?(file_content)
    doc = Nokogiri::HTML(file_content)
    parsed_json = JSON.parse(doc)
    parsed_json['value'].empty?
  end  

  def get_profiles(file_content)
    doc = Nokogiri::HTML(file_content)
    parsed_json = JSON.parse(doc)
    values = parsed_json['value']
    booking_nos = values.map { |record| record['BOOKINGNO'] }    
    booking_nos
  end  

  def get_inmate_addinfo(file_content,profile_link,inmate_id_counter)
    doc = Nokogiri::HTML(file_content)
    parsed_json = JSON.parse(doc)
    values = parsed_json['value']
    inmate_data = []
    height,weight,hair_color,eye_color,age,current_location = nil
    values.each do |record|
      height ||= record['FEET'].to_s + "'" + record['INCHES'].to_s + "''"
      weight ||= record['PERSON_WEIGHT_LAST']
      hair_color ||= record['HAIR']
      eye_color ||= record['EYE'] 
      age ||= record['AGE']
      current_location ||= record['FACILITY_ABBR']
    end  
    inmate_data << {
        inmate_id: inmate_id_counter,
        height: height,
        weight: weight,
        hair_color: hair_color,
        eye_color: eye_color,
        age: age,
        current_location: current_location,
        data_source_url: profile_link
      }
    inmate_id_counter += 1
    inmate_data = inmate_data.map {|hash| add_md5(hash)}  
    [inmate_data, inmate_id_counter]
  end  

  def get_inmates(file_content,profile_link)
    doc = Nokogiri::HTML(file_content)
    parsed_json = JSON.parse(doc)
    values = parsed_json['value']
    inmate_data = []
    first_name, last_name, middle_name, sex, race = nil
    values.each do |record|
      first_name ||= record['USED_PERSON_FIRST']
      last_name ||= record['USED_PERSON_LAST']
      middle_name ||= record['USED_PERSON_MIDDLE']
      sex ||= record['GENDER']
      race ||= record['ETHNICITY']
    end
      inmate_data << {
        first_name: first_name,
        last_name: last_name,
        middle_name: middle_name,
        sex: sex,
        race: race,
        data_source_url: profile_link
      }
    inmate_data = inmate_data.map {|hash| add_md5(hash)}  
  end  

  def denver_arrests(file_content,page_url,inmate_id_counter)
    doc = Nokogiri::HTML(file_content)
    parsed_json = JSON.parse(doc)
    values = parsed_json['value']
    inmate_data = []
    values.each do |record|
      inmate_data << {
        #booking_num: record['BOOKINGNO'],
        inmate_id: inmate_id_counter,
        status: "active",
        data_source_url: page_url
      }    
      inmate_id_counter += 1
    end
    inmate_data = inmate_data.map {|hash| add_md5(hash)}
    [inmate_data, inmate_id_counter]
  end  

  def denver_arrests_update(file_content,page_url,inmate_id_counter2)
    doc = Nokogiri::HTML(file_content)
    parsed_json = JSON.parse(doc)
    values = parsed_json['value']
    inmate_data = []
    booking_number, booking_date = nil
    values.each do |record|
      booking_number ||= record['BOOKINGNO']
      booking_date ||= record['ARREST_BOOKING_DATE']
      booking_date = Date.parse(booking_date)
      booking_date = booking_date.strftime("%Y-%m-%d")
    end  
      inmate_data << {
        inmate_id: inmate_id_counter2,
        booking_number: booking_number,
        booking_date: booking_date,
        status: "active",
        data_source_url: page_url
      }    
      inmate_id_counter2 += 1
    inmate_data = inmate_data.map {|hash| add_md5(hash)}
    [inmate_data, inmate_id_counter2]
  end  

  def denver_inmateids(file_content,page_url,inmate_id_counter)
    doc = Nokogiri::HTML(file_content)
    parsed_json = JSON.parse(doc)
    values = parsed_json['value']
    inmate_data = []
    values.each do |record|
      inmate_data << {
        #booking_num: record['BOOKINGNO'],
        number: record['INMATE_NUMBER'],
        type: 'CD Number',
        data_source_url: page_url,
        inmate_id: inmate_id_counter
      }
      inmate_id_counter += 1
    end
    inmate_data = inmate_data.map {|hash| add_md5(hash)}
    [inmate_data,inmate_id_counter]

    #p inmate_data
    #hash = booking_nos.zip(cd_numbers).map { |booking_no, cd_number| { booking_no: booking_no, cd_numbers: cd_number } }
    #booking_nos.each do |booking_no|
    #profile_link = "https://denvergov.org/api/inmatelookup/odata/bookings?$count=true&$top=10&$skip=0&$filter=bookingno%20eq%20%27#{booking_no}%27"
    #page_response, status = @scraper.download_main_page(profile_link)
    #p page_response.body
    #end  
  end  


end
