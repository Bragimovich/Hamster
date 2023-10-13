class Parser
  def add_data_soruce_md5(hash)
    hash['deleted'] = 0
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end

  def clear_text(address)
    address = address.gsub("Charges Filed", '').gsub("WAPEHD", '').gsub("State Prison", '').gsub("Arrest Type", '').gsub("Pickup", '').gsub("Own", '').gsub("\n", '').gsub("\\n", '').gsub("GC 6254(f)1", '').gsub("/", '').gsub("Commuted Time", '').gsub("Race" ,'' ).gsub("Temp",'').gsub("Arrest Date Time",'').gsub("Release",'').gsub("Date Arrest",'').gsub("On View", '').gsub("Remand",'').gsub("BookDate Time", '').gsub("DateOfBirth",'').gsub("Booking #", '').gsub("Bail Amount", '').gsub("849PC No ", '').gsub("Commitment", '').gsub("Court Order - ", '').gsub("Ramey Warrant", '').gsub("Name",'').gsub("Agency Warrant",'').squish         
  end

  def get_page_info(total_page)
    people = []
    addresses = []
    dob_matches = total_page.scan(/(am|pm)\s+(\d{2})\/(\d{2})\/(\d{4})/)
    rdate_matches = total_page.scan(/([MF])\s+(\d{2})\s+(\d{3})\s+([A-Z]{3}|t Specif t Spee)?\s+([A-Z]{3}|t Specif| t Spee)?\s+(.+)?(\d{1,2}\/\d{1,2}\/\d{2}\s+\d{1,2}:\d{2}\s+(?:am|pm))(?:\s+(.+)?(\d{2}\/\d{2}\/2023))?/i)
    race_matches = total_page.scan(/Arrest Location\s+(\w+)/)
    names = total_page.scan(/Bail Amount\s*\n\s*((?:\w+['\s-]?)+),\s*(\w+)/)
    height_patterns = total_page.scan(/([MF])\s+(\d{2})\s+(\d{3})/)
    hair_eyes_matches = total_page.scan(/([MF])\s+(\d{2})\s+(\d{3})\s+([A-Z]{3}|t Specif t Spee)?\s+([A-Z]{3}|t Specif| t Spee)?/)
    arrest_datetimes = total_page.scan(/\d{1,2}\/\d{1,2}\/\d{2}\s+\d{1,2}:\d{2}\s+(?:am|pm)/i)
    booking_matches = total_page.scan(/[A-Z]{2}\d{2}[A-Z]{2}\d{3}/)
    bail_amount_matches = total_page.scan(/\$[\d,]+(?:\.\d+)?/)
    job_matches = total_page.scan(/([MF])\s+(\d{2})\s+(\d{3})\s+([A-Z]{3}|t Specif t Spee)?\s+([A-Z]{3}|t Specif| t Spee)?\s+(.+)?(\d{1,2}\/\d{1,2}\/\d{2}\s+\d{1,2}:\d{2}\s+(?:am|pm))/i)
    address_pattern = /([MF])\s+(\d{2})\s+(\d{3})\s+([A-Z]{3}|t Specif t Spee)?\s+([A-Z]{3}|t Specif| t Spee)?\s+(.+)?(\d{1,2}\/\d{1,2}\/\d{2}\s+\d{1,2}:\d{2}\s+(?:am|pm))\s+(.+)?(?:\n\s*(?:, )?((?:CA \d{5})|(?:\b[A-Z]{2}\b.*)|(?:.*(?:\n|$))))/
    date_pattern = /\d{1,2}\/\d{1,2}\/\d{2}\s+\d{1,2}:\d{2}\s+(?:am|pm)\s/
    address_matches = total_page.scan(address_pattern)
    rel_typesmacthes = total_page.scan(/([MF])\s+(\d{2})\s+(\d{3})\s+([A-Z]{3}|t Specif t Spee)?\s+([A-Z]{3}|t Specif| t Spee)?\s+(.+)?(\d{1,2}\/\d{1,2}\/\d{2}\s+\d{1,2}:\d{2}\s+(?:am|pm))\s+(.+)?\s+(?:(\d{1,2}\/\d{1,2}\/2023))?/)
    bail_amounts = []
    arrest_dates = []
    book_dates = []
    release_dates = []
    addresses = []
    rel_types = []
    if rel_typesmacthes
      rel_typesmacthes.each do |rel_typesmatch|
       if rel_typesmatch[7].match?(/\d{2}\/\d{2}\/\d{4}/)
           rel_type = rel_typesmatch[7].split(/\d{2}\/\d{2}\/\d{4}/, 2)
             rel_types << rel_type[0]
       else 
          rel_types << 'NULL'
       end
      end  
    end  
    if address_matches
      address_matches.each do |address_match|
        address_match = address_match[7] + " " + address_match[8]
        if address_match.match?(/\d{2}\/\d{2}\/\d{4}/)
          address = address_match.split(/\d{2}\/\d{2}\/\d{4}/, 2)           
          address = clear_text(address[1]) 
          addresses << address         
        else
          address = clear_text(address_match)
          addresses << address
        end   
    end
    addresses.map! { |entry| entry.empty? ? 'NULL' : entry }
    end
    if arrest_datetimes
      arrest_datetimes.each_with_index do |arrest_datetime, index|
        if index % 2 == 0
          book_date = arrest_datetime
          book_dates << book_date
        else
          arrest_date = arrest_datetime
          arrest_dates << arrest_date
        end
      end
    end
    dob_matches.each do |dob_match|
      if dob_match[3] != '2023'
        month = dob_match[1]
        day = dob_match[2]
        year = dob_match[3]
        dob = "#{year}-#{month}-#{day}"
        people << { date_of_birth: dob }
      end
    end
    if bail_amount_matches
     bail_amount_matches.each do |bail_amount_match|
      if bail_amount_match != "$950" &&  bail_amount_match != "$400" 
       bail_amounts << bail_amount_match
      end  
     end
    end  
    names.each_with_index do |name, i|
      race = race_matches[i][0]
      gender = height_patterns[i][0]
      height = height_patterns[i][1]
      weight = height_patterns[i][2]
      if (hair_eyes_matches[i][3] != nil)
        hair = hair_eyes_matches[i][3].gsub("t Specif",'NULL')
        eyes = hair_eyes_matches[i][4].gsub("t Specif",'NULL')
      else
        hair = 'NULL'
        eyes = 'NULL'
      end     
      booking_number = booking_matches[i]
      name = name[0] + ',' + name[1]
      people[i] ||= {}
      people[i][:name] = name
      people[i][:race] = race
      people[i][:gen] = gender
      people[i][:height] = height
      people[i][:weight] = weight
      people[i][:hair] = hair
      people[i][:eyes] = eyes
      people[i][:arrest_date_time] = arrest_dates[i]
      people[i][:book_date_time] = book_dates[i]
      people[i][:booking_num] = booking_matches[i]
      people[i][:bail_amout] = bail_amounts[i]
      if job_matches[i][5] != nil
         people[i][:job_description] = job_matches[i][5].gsub("t Spee",'').gsub("t Specif",'').squish
      else
        people[i][:job_description] = 'NULL'
      end
      if rdate_matches[i][8] != nil
        date = Date.strptime(rdate_matches[i][8], '%m/%d/%Y')
        people[i][:release_date] = date.strftime('%Y-%m-%d') 
      else
        people[i][:release_date] = 'NULL'
      end 
      people[i][:arrest_location] = addresses[i]
      people[i][:rel_type] = rel_types[i]
    end
    people = people.map {|hash| add_data_soruce_md5(hash)} 
    people   
end  

def parse_charge_desc(document)
  data_array = []
  name_indices = []
  document.each_index.select { |i| document[i].downcase.include? 'booking' }.each { |i| name_indices << i }
  name_indices.each_with_index do |name_index,index|
    doc_name = document[name_index + 1...name_indices[index + 1]]
    arrest_type_indices = []
    doc_name.each_index.select { |i| doc_name[i].downcase.include? 'arrest type' }.each { |i| arrest_type_indices << i }
    arrest_type_indices.each_with_index do |arrest_index,index|
      doc_arrest = arrest_type_indices[index + 1].nil? ? doc_name[arrest_index + 1..] : doc_name[arrest_index + 1..arrest_type_indices[index + 1]]
      charge_description_list = doc_arrest.select{|e| e.downcase.include? 'charge description'}
      arrest_type = doc_arrest.first.split('  ').reject{ |e| e.empty? }.first.strip
      charge_description_list.each do |value|
        data_hash = {}
        heading_index = doc_arrest.index(value)
        required_values = doc_arrest[heading_index + 1].split('  ').reject{ |e| e.empty? }
        data_hash[:name] = doc_name.first.split('  ').reject{ |e| e.empty? }.first.strip
        data_hash[:arrest_type] = arrest_type
        data_hash[:charge] = required_values.first.strip
        if !required_values[2].nil?
          data_hash[:charge_description] = required_values[1].strip + " " + required_values[2].strip
        else
          data_hash[:charge_description] = required_values[1].strip
        end
        data_array << data_hash
        doc_arrest = doc_arrest[heading_index + 1..]
      end
    end
  end
  data_array.uniq
  data_array = data_array.map {|hash| add_data_soruce_md5(hash)} 
  data_array
end
end