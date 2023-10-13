class Parser <  Hamster::Parser

  def csv_data(file, run_id, db_md5)
    csv_array = []
    csv_data = JSON.parse(file)
    csv_data.each do |row|
      row_hash = {}
      row_hash[:case_number] = row['casenumber']
      row_hash[:incident_date] = splitting(row['incident_date'])
      row_hash[:death_date] = splitting(row['death_date'])
      row_hash[:age] = row['age']
      row_hash[:gender] = row['gender']
      row_hash[:race] = row['race']
      row_hash[:latino] = row['latino']
      row_hash[:manner_of_death] = row['manner']
      row_hash[:primary_cause] = row['primarycause']
      row_hash[:primary_cause_line_a] = row['primarycause_linea']
      row_hash[:primary_cause_line_b] = row['primarycause_lineb']
      row_hash[:primary_cause_line_c] = row['primarycause_linec']
      row_hash[:secondary_cause] = row['secondarycause']
      row_hash[:gun_related] = row['gunrelated']
      row_hash[:opioid_related] = row['opioids']
      row_hash[:cold_related] = row['cold_related']
      row_hash[:heat_related] = row['heat_related']
      row_hash[:incident_address] = row['incident_street']
      row_hash[:incident_city] = row['incident_city']
      row_hash[:incident_zipcode] = row['incident_zip']
      row_hash[:longitude] = row['longitude']
      row_hash[:residence_city] = row['residence_city']
      row_hash[:residence_zip] = row['residence_zip']
      row_hash[:objectid] = row['objectid']
      row_hash[:commissioner_district] = row['commissioner_district']
      row_hash[:latitude] = row['latitude']
      row_hash[:location] = row_hash[:longitude] && row_hash[:latitude] != nil ? "(#{row_hash[:longitude]}, #{row_hash[:latitude]})" : nil
      row_hash = hash_fixing(row_hash)
      md5_hash = create_md5_hash(row_hash)
      next if db_md5.include? md5_hash
      row_hash[:data_source_url] = "https://datacatalog.cookcountyil.gov/api/views/cjeq-bs86/rows.csv?accessType=DOWNLOAD&bom=true&query=select+*"
      row_hash[:run_id] = run_id
      csv_array << row_hash
    end
    csv_array
  end

  private

  def hash_fixing(row_hash)
    row_hash.keys.each do |key|
      if row_hash[key].to_json == "false"
        row_hash[key] = 0
      elsif row_hash[key].to_json == "true"
        row_hash[key] = 1
      end
    end
    row_hash
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def splitting(dates)
    begin
      date_inc = dates.split('T')
      date_inc[0].to_date
    rescue
      nil
    end
  end

end
