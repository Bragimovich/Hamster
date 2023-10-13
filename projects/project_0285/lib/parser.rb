class Parser < Hamster::Parser

  def html_parsing(html)
    Nokogiri::HTML(html.force_encoding('utf-8'))
  end

  def get_data(data, run_id, search_params)
    doc = html_parsing(data)
    data_array = []
    md5_hash_array = []
    tables = doc.css('.scale-in-center')
    tables.each do |table|
      spans = table.css('span')
      data_hash = {}
      vcard_index = table.css('a')[0]['href'].split('/').last
      data_hash[:vcard_index]            = vcard_index
      data_hash[:full_name]              = table.css('.title').text.squish
      employee_information               = search(spans, 'Employee Information')
      data_hash[:employee_type], data_hash[:employee_department] = seperate_employee_info(employee_information)
      data_hash[:employee_information]                           = employee_information
      data_hash[:email]                                          = search(spans, 'Email')
      data_hash[:office_mailing_address] = search(spans, 'Office Mailing Address')
      data_hash[:student_campus]         = search(spans, 'Student Campus')
      data_hash[:student_plans]          = student_plan_fetching(table, 'Student Plan(s)')
      data_hash[:md5_hash]               = create_md5_hash(data_hash)
      data_hash[:mobile_number]          = search(spans, 'Mobile Phone')
      data_hash[:office_phone]           = search(spans, 'Office Phone')
      data_hash[:search_params]          = search_params
      data_hash[:first_name], data_hash[:last_name], data_hash[:middle_name] = splitting_names(data_hash[:full_name])
      data_hash[:nickname]               = search(spans, 'Nickname')
      md5_hash_array << data_hash[:md5_hash]
      data_hash.delete(:md5_hash)

      data_hash[:last_scrape_date]       = Date.today
      data_hash[:next_scrape_date]       = Date.today + 1
      data_hash[:run_id]                 = run_id
      data_hash[:touched_run_id]         = run_id
      data_array << data_hash
    end
    [data_array, md5_hash_array]
  end

  private

  def student_plan_fetching(table, key)
    if table.text.squish.include? key
      data = table.text.squish.split(key)
      value = data[1]
    else
      nil
    end
  end

  def splitting_names(name)
    name_split = name.split
    first_name = name_split[0].gsub(',', '')
    l_name = name_split[1]
    last_name = (l_name.include? ',') ? l_name.gsub(',','') : l_name  rescue nil
    middle_name = (name_split.count > 2) ? name_split.last : nil
    [first_name, last_name, middle_name]
  end

  def search(span ,key)
    value = (span.select {|e| e.text.start_with? key}[0].nil?) ? nil : span.select {|e| e.text.start_with? key}[0].next_element
    (value.nil?) ? nil : value.text.strip.squish
  end

  def seperate_employee_info(employee_info)
    splitting_info = (employee_info.nil?) ? nil : employee_info.split(',')
    (splitting_info.nil?) ? [nil, nil] : ["#{splitting_info[0].squish}", "#{splitting_info[1]} #{splitting_info[2]}".squish]
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.each_value do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
