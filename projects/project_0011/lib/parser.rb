class Parser < Hamster::Parser

  def parse_page(response)
    Nokogiri::HTML(response)
  end

  def get_current_date(html_page)
    response = parse_page(html_page.body)
    date = response.css(".additional-info table tbody tr")[0].css("td").text.squish.split(",")[0..1].join(",")
    format_date(date)
  end

  def get_csv_links(html_page)
    response = parse_page(html_page.body)
    response.css("#dataset-resources ul.resource-list li.resource-item").map{|e| e.css("div.dropdown ul.dropdown-menu li")[-1].css("a")[0]['href']}[1..]
  end

  def get_csv_names(html_page)
    response = parse_page(html_page.body)
    response.css("#dataset-resources ul.resource-list li.resource-item").map{|e| e.css("a")[0]['title']}[1..]
  end

  def create_hash(csv_hash, run_id, csv_file_name)
    csv_hash["DateApproved"] = get_format_date(csv_hash["DateApproved"])
    csv_hash["LoanStatusDate"] = get_format_date(csv_hash["LoanStatusDate"])
    csv_hash["ForgivenessDate"] = get_format_date(csv_hash["ForgivenessDate"])
    csv_hash = mark_empty_as_nil(csv_hash)
    csv_hash["pl_gather_task_id"] = 0
    csv_hash["scrape_frequency"] = "Monthly"
    csv_hash["data_source_url"] = "https://data.sba.gov/dataset/ppp-foia"
    csv_hash["last_scrape_date"] = "#{Date.today}"
    csv_hash["next_scrape_date"] = "#{Date.today.next_month}"
    csv_hash["scrape_dev_name"] = "Adeel"
    csv_hash["file_name"] = csv_file_name
    csv_hash["run_id"] = run_id
    csv_hash["touched_run_id"] = run_id
    csv_hash
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
  
  def get_format_date(string_date)
    if string_date.nil? || string_date.empty?
      string_date = nil
    else
      input_format = "%m/%d/%Y"
      output_format = "%Y-%m-%d"
      string_date = Date.strptime(string_date, input_format).strftime(output_format) rescue nil
    end
  end

  private
  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == 'null') ? nil : value.to_s.squish}
  end

  def format_date(date)
    input_format = "%B %d, %Y" 
    Date.strptime(date, input_format)
  end

end
