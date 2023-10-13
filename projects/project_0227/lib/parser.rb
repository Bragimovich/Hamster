class Parser < Hamster::Parser

  def fetch_values(html)
    data = Nokogiri::HTML(html.force_encoding('utf-8'))
    data = data.css('#row-no-padding select option').map { |e| e['value'] }
    data[1..]
  end

  def fetch_auth(html)
    data  = Nokogiri::HTML(html.force_encoding('utf-8'))
    data  = data.css('head script').last.to_s.split('[')[1].split(']')
    auth_one = data[0].split('{')[1].split('authorization')[1][3..-4]
    auth_two = data[0].split('{')[3].split('authorization')[1][3..-3]
    csrf_one = data[0].split('{')[1].split('authorization')[0].split('csrf')[1][3..-4]
    csrf_two = data[0].split('{')[3].split('authorization')[0].split('csrf')[1][3..-4]
    [auth_one, auth_two, csrf_one, csrf_two]
  end

  def fetch_json_info(data, run_id)
    data       = JSON.parse(data)
    data_array = []
    md5_hash_arry = []
    records    = data[1]['result']['v'] rescue nil
    records    = data[1]['result'] if records.nil?
    records.each do |record|
      data_hash = find_record_data(record, run_id)
      md5_hash_arry << data_hash.delete(:md5_hash)
      data_array << data_hash unless (data_hash[:license_num].nil? and data_hash[:issue_date].nil?)
    end
    [data_array, md5_hash_arry]
  end

  private

  def fetch_name_from_json(record, is_business_license)
    name        = record.deep_find('Applicant_Full_Name__c') unless is_business_license
    name        = record.deep_find('Licensee_Name__c') if is_business_license
    name        = record.deep_find('Name') if name.nil?
    first_name  = record.deep_find('FirstName')
    middle_name = record.deep_find('Middle_Name__c')
    last_name   = record.deep_find('LastName')
    [name, first_name, middle_name, last_name]
  end

  def find_sub_status(record)
    sub_status = record.deep_find('SubStatus')
    sub_status = record.deep_find('Sub_Status__c') if (sub_status.nil? or sub_status.empty?)
    sub_status
  end

  def find_license_number(record)
    license_num = record['license']['Name'] rescue nil
    license_num = record.deep_find('RecNumber') if (license_num.nil? or license_num.empty?)
    license_num = record.deep_find_all('Name').select {|e| (e.include? '.' or e.include? '-') and e.count("0-9") > 1}[0] if (license_num.nil? or license_num.empty?)
    license_num
  end

  def find_city_and_state(record)
    city  = record.deep_find('City')
    city  = record.deep_find('Applicant_City__c') if city.nil?
    state = record.deep_find('State')
    state = record.deep_find('Applicant_State__c') if state.nil?
    [city, state]
  end

  def find_id(record)
    id = record.deep_find('Id')
    id = record.deep_find('License__c') if id.nil?
    id
  end

  def find_record_data(record, run_id)
    record.extend Hashie::Extensions::DeepFind
    is_business_license = record.deep_find('Business_License__c')
    name, first_name, middle_name, last_name = fetch_name_from_json(record, is_business_license)
    sub_status   = find_sub_status(record)
    license_num  = find_license_number(record)
    city, state  = find_city_and_state(record)
    board_action = record.deep_find('BoardAction')
    id = find_id(record)
    data_hash                        = {}
    if is_business_license
      data_hash[:company_name]       = name
      data_hash[:name]               = nil
    else
      data_hash[:name]               = name
      data_hash[:company_name]       = nil
    end
    data_hash[:status]               = record.deep_find('Status')
    data_hash[:sub_status]           = sub_status
    data_hash[:sub_category]         = record.deep_find('Sub_Category__c')
    data_hash[:board]                = record.deep_find('Board')
    data_hash[:license_type]         = record.deep_find('MUSW__Type__c')
    data_hash[:license_num]          = license_num
    data_hash[:issue_date]           = get_date(record.deep_find('MUSW__Issue_Date__c'))
    data_hash[:effective_date]       = get_date(record.deep_find('Effective_Date__c'))
    data_hash[:expiration_date]      = get_date(record.deep_find('MUSW__Expiration_Date__c'))
    data_hash[:city]                 = city
    data_hash[:state]                = state
    data_hash[:country]              = record.deep_find('Parcel_Country__c')
    data_hash[:zip]                  = record['zipcode']
    data_hash[:address]              = record['streetaddress']
    data_hash[:county]               = record['County']
    data_hash[:is_business_license]  = is_business_license ? 1 : 0
    data_hash[:board_action]         = board_action.split("\;")[0] rescue nil
    data_hash[:data_source_url]      = "https://elicense.ohio.gov/oh_verifylicensedetails?pid=#{id}"
    data_hash                        = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash]             = create_md5_hash(data_hash)
    data_hash[:issue_date_unix_timestamp]      = record.deep_find('MUSW__Issue_Date__c')
    data_hash[:effective_date_unix_timestamp]  = record.deep_find('Effective_Date__c')
    data_hash[:expiration_date_unix_timestamp] = record.deep_find('MUSW__Expiration_Date__c')
    data_hash[:run_id]               = run_id
    data_hash[:touch_run_id]         = run_id
    data_hash[:multi_state_eligible] = record.deep_find('Compact')
    if is_business_license
      data_hash[:first_name], data_hash[:middle_name], data_hash[:last_name] = nil
    else
      first_name, middle_name, last_name = fetch_name(name) if (first_name.nil? and last_name.nil?)
      data_hash[:first_name]  = first_name
      data_hash[:middle_name] = middle_name
      data_hash[:last_name]   = last_name
    end
    data_hash = mark_empty_as_nil(data_hash)
    data_hash
  end

  def get_date(date)
    Time.at(date/1000).in_time_zone('GMT').to_date rescue nil
  end

  def fetch_name(name)
    name        = name.split
    first_name  = name.delete_at(0)
    last_name   = name.delete_at(-1)
    middle_name = name.join(' ')
    [first_name, middle_name, last_name]
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

end
