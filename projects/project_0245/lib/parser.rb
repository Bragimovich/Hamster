class Parser <  Hamster::Parser
  DOMAIN = 'https://www.elections.alaska.gov'

  def fetch_main_page(response,year)
    data_array = []
    main_page = parse_response(response)
    all_links = main_page.css("div.rbox.colsngl").css("u").css("a").select{|s| s[:href].include? year.to_s}
    all_links.each do |link|
      main_link = link['href']
      full_date = link.text
      data_array << [main_link, full_date]
    end
    data_array
  end
  
  def pdf_reading(path, run_id, full_date, link)
    data_array = []
    pdf_reader = PDF::Reader.new(open(path)) 
    document = pdf_reader.pages[1].text.scan(/^.+/)
    document = fetch_document(document, pdf_reader)

    document.each_with_index do |row, index|
      next if row.include? "HOUSE" || "TOTAL" || "STATE" || "VOTER" || "IN HOUSE"
      
      first_two_index = document[index].split('  ').reject{|e| e.empty?} rescue nil

      next if (first_two_index.nil? || first_two_index.length < 5)
      all_indexes = document[index].split('  ').reject{|e| e.empty?}[2..-1].join("  ").scan(/\d+/)
      
      data_hash = {}
      data_hash[:full_date], data_hash[:year], data_hash[:month], data_hash[:day] = extract_date(full_date)
      
      data_hash[:district] = first_two_index[0].split('-').first.strip
      data_hash[:precinct] = first_two_index[0..1].join(" ")
      data_hash[:total] = all_indexes[0]
      data_hash[:independence_party] = all_indexes[1]
      data_hash[:constitution_party] = all_indexes[2]
      data_hash[:democratic_party] = all_indexes[3]
      data_hash[:moderate_party] = all_indexes[4]
      data_hash[:freedomreform_party] = all_indexes[5]
      data_hash[:green_party] = all_indexes[6]
      data_hash[:owl_party] = all_indexes[7]
      data_hash[:alliance_party] = all_indexes[8]
      data_hash[:libertarian_party] = all_indexes[9]
      data_hash[:nonpartisan] = all_indexes[10]
      data_hash[:progressive_party] = all_indexes[11]
      data_hash[:patriots_party] = all_indexes[12]
      data_hash[:republican_party] = all_indexes[13]
      data_hash[:undeclared] = all_indexes[14]
      data_hash[:veterans_party] = all_indexes[15]
      data_hash[:uces_clowns_party] = all_indexes[16]
      data_hash[:link] = link
      data_hash[:data_source_url] = "https://www.elections.alaska.gov/doc/info/statsPPA.php"
      data_hash[:run_id] = run_id
      data_array << data_hash
    end
    data_array
  end
  
  def voters_info_parser(response, run_id, full_date, link)
    data_array = []
    document = parse_response(response)
    all_tables = document.css("table[align='center']")[2..-1]
    all_tables.each do |table| 
      headers = table.css("tr")[1].css("td")[4..-1].map{|s| s.text} 
      district = table.css("tr")[1].css("td")[0].text.split(" ")[-1]
      all_precinct = table.css("tr")[2..-3]
      all_precinct.each_with_index do |row,index|
        voter_hash = {}
        voter_hash[:full_date], voter_hash[:year], voter_hash[:month], voter_hash[:day] = extract_date(full_date)
        voter_hash[:district] = district
        voter_hash[:link] = link
        voter_hash[:data_source_url]   = "https://www.elections.alaska.gov/doc/info/statsPPA.php"
        voter_hash = create_record(headers,row.css("td:not([style='display:none'])"),voter_hash)
        voter_hash[:run_id] = run_id
        data_array << voter_hash
      end
    end
    data_array
  end

  private

  def fetch_document(document, pdf_reader)
    pdf_reader.pages.each_with_index do |page, index|
      next if index == 0 || index == 1
      document = document + page.text.scan(/^.+/)
    end
    document
  end

  def extract_date(full_date)
    date_split = full_date.split.first.split('/')
    [full_date, date_split[-1], date_split.first, date_split[1]]
  end

  def parse_response(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def parties_hash
    {
      "A" => "independence_party", 
      "D" => "democratic_party", 
      "R" => "republican_party", 
      "C" => "constitution_party", 
      "E" => "moderate_party",
      "F" => "freedomreform_party", 
      "G" => "green_party", 
      "H" => "owl_party", 
      "K" => "alliance_party", 
      "L" => "libertarian_party", 
      "O" => "progressive_party", 
      "P" => "patriots_party", 
      "V" => "veterans_party", 
      "W" => "uces_clowns_party", 
      "N" => "nonpartisan", 
      "U" => "undeclared", 
      "T" => "twelve_visions_party"
    }
  end

  def create_record(headers,row, hash)
    row.each_with_index do |record, index_no|
      hash[:precinct] = record.text if index_no == 0
      hash[:total] = record.text if index_no == 1
      if index_no > 1
        hash[parties_hash[headers[index_no-2]]] = record.text
      end
    end
    hash
  end
end
