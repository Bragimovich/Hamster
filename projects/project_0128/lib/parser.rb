# frozen_string_literal: true

class Parser < Hamster::Parser
  def get_csv_data(file)
    CSV.parse(file, headers: true, liberal_parsing: true)
  end

  def get_crimes_data(crime_codes, all_data)
    crimes_array = []
    all_data[0..].each_with_index do |row, _index|
      all_crimes = row[18..].reject(&:nil?)
      all_crimes.each_with_index do |crime, _ind|
        crime = crime.split('-', 2)
        code = crime[0].strip
        next if crime_codes.include? code.to_s

        description = crime[-1].strip
        data_hash = {
          crime_code: code,
          crime_description: description
        }
        crimes_array << data_hash
      end
    end
    crimes_array
  end

  def fetch_full_name(first_name, middle_name, last_name)
    if middle_name.nil?
      full_name = [first_name, last_name].join(' ')
    else
      full_name = [first_name, middle_name, last_name].join(' ')
    end
    full_name
  end

  def get_parsed_hash(row, _index, run_id)
    data_hash = {}

    data_hash[:full_name] = fetch_full_name(row['First Name'], row['Middle Name'], row['Last Name'])
    data_hash[:status] = row['Status']
    data_hash[:date_of_birth] =  Date.strptime(row['Date of Birth'], '%m/%d/%Y').to_date
    data_hash[:height] = row['Height'].gsub("'", ' ft.').gsub('"', ' in.')
    data_hash[:weight] = row['Weight'].gsub('.', '')
    data_hash[:sex] = row['Gender']
    data_hash[:race] = row['Race']
    
    data_hash[:address1] = row['Address'].strip rescue nil
    data_hash[:address2] = nil
    data_hash[:city] = row['City']
    data_hash[:state] = row['State']
    data_hash[:zip] = row['Zip Code']
    if !data_hash[:address1].nil?
      full_address = [data_hash[:address1], data_hash[:city], data_hash[:state],data_hash[:zip]].join(' ')
      data_hash[:full_address] = full_address
    else
      data_hash[:full_address] = nil
    end
    
    data_hash[:title] = row['Classification']
    data_hash[:victim_age_at_time_of_offense] = row['Age of Victim']
    data_hash[:offender_age_at_time_of_offense] = row['Age of Offender at Time of Offense']
    data_hash[:county_of_conviction] = row['Conviction State or IL County']
    data_hash[:residence_county] = row['Residence County']
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)

    data_hash[:last_name] = row['Last Name']
    data_hash[:first_name] = row['First Name']
    data_hash[:middle_name] = row['Middle Name']
    data_hash[:year] = Date.today.year.to_s
    data_hash[:run_id] = run_id
    
    data_hash[:last_scrape_date] = Date.today
    data_hash[:next_scrape_date] = Date.today.next_day
    data_hash
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : ((value.to_s.valid_encoding?)? value.to_s.squish : value.to_s.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '').squish)}
  end

  def fetch_crimes(row, sex_offender_id, crimes_details)
    crimes_array = []
    all_crimes = row[18..].reject(&:nil?)
    all_crimes.each do |crime|
      code = crime.split('-').first.strip
      crime_id = crimes_details.select { |a| a[:crime_code] == code.to_s }.first[:id]
      data_hash = {
        sex_offender_id: sex_offender_id,
        crime_code_id: crime_id
      }
      crimes_array << data_hash
    end
    crimes_array
  end

  def create_md5_hash(data_hash)
    data_hash = data_hash.except(:address1)
    data_hash = data_hash.except(:address2)
    data_hash = data_hash.except(:city)
    data_hash = data_hash.except(:zip)
    data_hash = data_hash.except(:state)
    data_string = ''
    data_hash.each_value do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
