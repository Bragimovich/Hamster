class Parser < Hamster::Parser

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def get_links(page)
    page.css('table[class="cbResultSetTable cbResultSetTableCellspacing"]').first.css('tr')[1..-1].map{|e| e.css('a[target="_blank"]')[0]['href']}
  end

  def parser(html, link, run_id )
    document = parse_page(html)
    data = document.css("tr")
    md5_array = []
    data_hash = {}
    text = document.css("h2").first&.text
    unless text.nil? || !text.include?("salary")
      data_hash[:full_name] = text.split("salary").first&.gsub(/'s\s*\z/, '')&.strip
      data_hash[:first_name], data_hash[:middle_name], data_hash[:last_name] = name_partition(data_hash[:full_name])
    end
    data.shift
    data.each do |tr|
      td = tr.css("td")
      data_hash[td[0].nil? ? nil : td[0].text.strip.downcase.gsub(" ","_").to_sym] = td[1].nil? ? nil : td[1].text.strip
    end
    data_hash = set_value(data_hash)
    return if data_hash.values.all?(&:nil?)
    data_hash[:md5_hash] = create_md5_hash(mark_empty_as_nil(data_hash))
    md5_array << data_hash[:md5_hash]
    data_hash[:data_source_url] = "#{link}"
    data_hash[:scrape_dev_name]           = "Aqeel"
    data_hash[:scrape_frequency]          = "yearly"
    data_hash[:last_scrape_date]          = Date.today
    data_hash[:next_scrape_date]          = Date.today + 365
    data_hash[:pl_gather_task_id]         = 167980503
    data_hash[:dataset_name_prefix]       = "az_public_employee_salary"
    data_hash[:expected_scrape_frequency] = "yearly"
    data_hash[:scrape_status]             = "processing"
    data_hash[:run_id]                    = run_id
    data_hash[:touched_run_id]            = run_id
    data_hash unless data_hash[:first_name].nil?
    [data_hash , md5_array]
  end

  private

  def name_partition(full_name)
    return [] if full_name.nil?
    data        = full_name.split(' ')
    first_name  = data[0] rescue nil
    middle_name = data.length == 4 ? data[1..2].join(' ') : data[1]
    last_name   = data[-1]&.gsub(/'s\s*\z/, '')
    middle_name = nil if data.length == 2
    [first_name, middle_name, last_name]
  end

  def set_value(data_hash)
    data_hash[:employer] = data_hash.delete(:agency)
    data_hash[:full_time_or_part_time] = data_hash.delete(:full_or_part_time_status)
    data_hash[:department_state_clear] = data_hash[:department]
    data_hash[:hire_date]              = Date.strptime(data_hash[:hire_date], "%m/%d/%Y").to_date rescue nil
    data_hash[:other_notes]            = data_hash[:other_notes].nil? || data_hash[:other_notes].length < 3 ? nil : data_hash[:other_notes]
    data_hash[:annual_pay]             = value_formation(data_hash[:annual_pay])
    data_hash[:hourly_rate]            = value_formation(data_hash[:hourly_rate])
    data_hash[:overtime]               = value_formation(data_hash[:overtime])
    data_hash
  end

  def value_formation(name_string)
    name_string.nil? ? nil : name_string.scan(/([A-Za-z0-9.]+)/).flatten.join.to_i
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "null") ? nil : value}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
