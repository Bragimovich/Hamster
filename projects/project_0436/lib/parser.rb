class Parser <  Hamster::Parser
  DOMAIN = "https://transparentnevada.com"

  def main_page_body(response)
    page_scraper = parsing(response.body)
    page_scraper.css('ul.nav-tabs li')[0..3]
  end

  def all_tabs_link(main_ul_link)
    all_tab_links = []
    main_ul_link.each do |main_link|
      all_tab_links << DOMAIN + main_link.css('a')[0]['href']
    end
    all_tab_links
  end

  def tab_page_link(url)
    category_array = []
    csv_link_response = parsing(url)
    all_categories = csv_link_response.css('table.agency-list tr')
    all_categories.each do |category|
      category_array << category.css("td")[0].css("a")[0]['href']
    end
    category_array
  end

  def each_csv_link_data(scraped_page)
    response = parsing(scraped_page)
    response.css("a.export-link").css("a").select{|a| a.text.split.last.to_i > 2015}.map{|a| a["href"]}
  end

  def parsing_csv(csv,run_id,link,inserted_records)
    doc = File.read(csv[0])
    all_data = CSV.parse(doc)
    csv_array = []
    all_data.each_with_index do |row, index|
      csv_hash = {}
      next if index == 0
      csv_hash[:year] = row[8]
      csv_hash[:full_name] = row[0]
      csv_hash[:first_name], csv_hash[:middle_name], csv_hash[:last_name] =  full_name(csv_hash[:full_name]) 
      csv_hash[:job_title] = row[1]
      csv_hash[:agency] = row[10]
      csv_hash[:regular_pay] = row[2]
      csv_hash[:overtime_pay] = row[3]
      csv_hash[:other_pay] = row[4]
      csv_hash[:total_pay_and_benefits] = row[7]
      csv_hash[:total_pay] = row[6]
      csv_hash[:total_benefits] = row[5]
      csv_hash[:link] = link
      csv_hash[:md5_hash] = create_md5_hash(csv_hash)
      next if inserted_records.include? csv_hash[:md5_hash]
      csv_hash.delete(:md5_hash)
      csv_hash[:run_id] = run_id
      csv_hash[:last_scrape_date] = Date.today
      csv_hash[:next_scrape_date] = Date.today + 365
      csv_array << csv_hash
    end
    csv_array
  end

  private 

  def parsing(pages)
    Nokogiri::HTML(pages.force_encoding("utf-8"))
  end

  def full_name(name)
    first_name = name.split(" ")[0]
    middle_name = name.split(" ").count > 2 ? name.split(" ")[1...-1].join(" ") : nil
    last_name = name.split(" ").last
    [first_name, middle_name, last_name]
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.each_value do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
