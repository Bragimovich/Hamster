class Parser
  SUB_FOLDER = 'FASFA_completion_school'
  STATES_DIRECTORY_NAME = "states"
  ARCHIVES_DIRECTORY_NAME = "archives"

  def parse_main_json_file(response)
    JSON.parse(response.body)['mainContent'].select{ | element | element['data'] }
  end

  def get_all_states_file_links_from_json(states_chunk)
    states = []
    state_list = states_chunk['data'][0]['data'][0]['data']
    state_list.each do |state|
      states << { 'state': state['value'], 'link': state['href'] }
    end
    states
  end

  def get_all_archives_file_links_from_json(archives_chunk)
    archives = [] 
    archives_list = archives_chunk['data']
    archives_list.each do |archive|
      year = archive['title']
      for record in archive['data'][0]['data'] do
        archives << { 'year': year ,'date': record['value'], 'link': record['href'] }
      end 
    end
    archives
  end

  def parse_xls(file_path , link , archive_file_type)
    hashed = []
    begin
      xls = Roo::Spreadsheet.open(file_path)
    rescue Ole::Storage::FormatError => error
      p error
      return []
    end
    data_with_header = xls.select {|item| !item.include? nil}
    headers = data_with_header[0].map {|item| item.split(" ").join(" ")}
    records = data_with_header[1..-1]

    if archive_file_type
      if file_path.include?("18yrold")
        age = '18'
      else
        age = '19'
      end
    end

    records.each do |rec|
      # One school has multiple admission times during a year so after first 3 or 4 columns, each 2 columns will be one entry
      # So we calculate the iterations we will be making on each record
      split_index = headers.index{|e| e.include?("Application")}
      iterations_on_record = headers[split_index..-1].length/2
      temp_headers = headers[split_index..-1]
      temp_rec = rec[split_index..-1]
      (1..iterations_on_record).each do |iteration|
        record = {}
        if archive_file_type
          record["age"] = age
        end
        if headers.index {|e| e.include?("School Code")}.present?
          record['school_code'] = rec[headers.index {|e| e.include?("School Code")}]
        end
        record["name"] = rec[headers.index {|e| e.include?("Name")}]

        city_index = headers.index { |e| e.include?("City") }
        city_value = city_index ? rec[city_index] : nil
        record["city"] =  city_value
        record["state"] = rec[headers.index {|e| e.include?("State")}]
        record["applications_submitted"] = temp_rec[0].strip()
        record["applications_submitted_on"] = temp_headers[0].split(" ")[2..-1].join(" ")
        record["applications_complete"] = temp_rec[1].strip()
        record["applications_completed_on"] = temp_headers[1].split(" ")[2..-1].join(" ")
        year = temp_headers[0].split(" ")[-1].to_i
        record["cycle"] = "#{year}/#{year+1}"
        record["through_date"] = fix_date(temp_headers[1].split(" ")[2..-1].join(" "))
        record["data_source_url"] = link
        hashed << record
        # poping first two records from temp_rec and temp_header
        temp_rec.shift(2)
        temp_headers.shift(2)
      end
    end
    hashed
  end

    
  def fix_date(date_to_fix)
    first_num_in_date = /\d+/.match(date_to_fix).to_s
    if first_num_in_date.length > 2
      "#{date_to_fix}"
    else
      index = date_to_fix.index(first_num_in_date)
      leftover = date_to_fix[index..-1].split(" ")
      month = date_to_fix[0..index-1]
      year = leftover[1].strip()
      "#{month} #{first_num_in_date}, #{year}"
    end
  end

end