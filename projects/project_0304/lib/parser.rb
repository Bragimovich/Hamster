class Parser < Hamster::Parser

  def parsing_html(page_html)
    Nokogiri::HTML(page_html.force_encoding('utf-8'))
  end

  def get_url(page)
    page.css('#aspnetForm')[0]['action'].split("/")[-1]
  end

  def get_links(main_page_parsing)
    link_array = []
    all_links = main_page_parsing.css("#ContentMain_C060_Col01 a")
    all_links.each_with_index do |link, idx|
      next_page_link = link["href"]
      link_array << next_page_link
    end
    link_array
  end

  def get_names(main_page_parsing)
    names_array = []
    all_name = main_page_parsing.css("#ContentMain_C060_Col01 a")
    all_name.each_with_index do |data, idx|
      name = data.text.gsub('Hurricane', '').gsub('Claims Data', '').squish
      name = (name.include? 'Claims')? name.split('Claims')[0].squish : name
      names_array << name
    end
    names_array
  end

  def insurance_hurricanes(hurricane_name, run_id)
    insurance_hurricanes_array = []
    hurricane_name.each do |name|
      hurricane_name_hash = {}
      hurricane_name_hash[:hurricane_name] = name
      hurricane_name_hash[:md5_hash] = create_md5_hash(hurricane_name_hash)
      hurricane_name_hash[:run_id] = run_id
      hurricane_name_hash[:touched_run_id] = run_id
      insurance_hurricanes_array << hurricane_name_hash
    end
    insurance_hurricanes_array
  end

  def hurricane_names(hurricane_parsing, idx)
    hurricane_parsing.css(".cols h1").text.gsub(" ","_")
  end

  def fetch_parent_name(all_categories, category_name)
    parent_name = ''
    all_categories.each do |val|
      break if val.text == category_name
      parent_name = (val.to_s.include? '<b>') ? val.text : next
    end
    parent_name
  end

  def get_business_categories(page)
    page.css("table.infotable")[0].css("td[1]")
  end

  def business_name(category)
    is_parent = (category.to_s.include? '<b>') ? 1 : 0
    [is_parent, category.text.strip.gsub('*','')]
  end

  def business_category_data(outer_id, category_name, is_parent, url, run_id)
    data_hash = {}
    data_hash[:categ_code] = outer_id
    data_hash[:categ_desc] = category_name
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://www.floir.com/Office/HurricaneSeason/#{url}"
    data_hash[:run_id]= run_id
    data_hash[:touched_run_id]= run_id
    data_hash[:is_parent] = is_parent
    data_hash
  end

  def data_categories(page, run_id, url)
    all_heads = page.css(".infotable thead tr th")
    data_categories_array = []
    all_heads.each_with_index do |data, idx|
      next if idx == 0
      next if data.text.squeeze(" ").strip.gsub("\n","").gsub("\r"," ").include? ("County"  || "County*")
      data_hash = general_data_category(data, url, run_id)
      data_categories_array << data_hash
    end
    unless page.css('b').select{|e| e.text == 'Total Estimated Insured Losses:'}.empty?
      data = page.css('b').select{|e| e.text == 'Total Estimated Insured Losses:'}.first
      data_hash = general_data_category(data, url, run_id)
      data_categories_array << data_hash
    end
    data_categories_array
  end

  def state_data(page, hurricane_id, category_ids, business_categ_ids, run_id, url)
    tables = page.css("table.infotable")
    all_headers = tables[0].css("tr").first.css('th').map(&:text).map(&:squeeze).map(&:squish)
    all_categories = tables[0].css("tr")
    state_data_array = []
    all_categories.each do |category|
      data_row = category.css("td")
      business_category = 0
      data_row.each_with_index do |data, index|
        if index == 0
          is_parent , biz_name = business_name(data)
          is_parent = (is_parent == 1) ? true : false
          business_category = business_categ_ids.select{|e| e[2] == biz_name && e[-1] == is_parent}.flatten.second
          next
        end
        state_data_array <<  general_data_state(data, url, run_id, business_category, hurricane_id, category_ids, all_headers, index)
      end
    end
    unless page.css('b').select{|e| e.text == 'Total Estimated Insured Losses:'}.empty?
      data = page.css('b').select{|e| e.text == 'Total Estimated Insured Losses:'}.first
      state_data_array << general_data_state(data, url, run_id, nil, hurricane_id, category_ids, all_headers, 0)
    end
    state_data_array
  end

  def insurance_counties(page, run_id, url)
    tables = page.css("table.infotable")
    insurance_counties_array = []
    if tables.count > 1
      all_counties = tables[1].css("td[1]")
      all_counties.each do |category|
        data_hash = {}
        data_hash[:county_name] = category.text
        data_hash[:md5_hash] = create_md5_hash(data_hash)
        data_hash[:data_source_url] = "https://www.floir.com/Office/HurricaneSeason/#{url}"
        data_hash[:run_id]= run_id
        data_hash[:touched_run_id]= run_id
        insurance_counties_array << data_hash
      end
    end
    insurance_counties_array
  end

  def county_data(page, hurricane_id, county_ids, category_ids, run_id, url)
    tables = page.css("table.infotable")
    insurance_counties_array = []
    if tables.count > 1
      all_dataCategories = tables[1].css("th")
      all_counties = tables[1].css("tr")
      all_counties.each_with_index do |county, idx|
        next if idx == 0
        county_data = county.css("td")
        county_id = county_ids.select{|s| s[-1] == county_data.first.text}.flatten.first
        all_dataCategories.zip(county_data).each do |title ,data|
          data_hash = {}
          next if title.text.include? "County"
          data_hash[:county_id] = county_id
          data_hash[:hurricane_id] = hurricane_id
          data_hash[:data_categ_id] = category_ids.select{|e| e[1] == title.text.squish}.flatten.first
          data_hash[:value] = data.text.gsub(",","").squish.to_f
          data_hash[:value_unit] = (data.text.include? "%") ? "%" : nil
          data_hash[:md5_hash] = create_md5_hash(data_hash)
          data_hash[:data_source_url] = "https://www.floir.com/Office/HurricaneSeason/#{url}"
          data_hash[:run_id]= run_id
          data_hash[:touched_run_id]= run_id
          insurance_counties_array << data_hash
        end
      end
    end
    insurance_counties_array
  end

  private

  def general_data_state(data, url, run_id, business_category, hurricane_id, category_ids, all_headers, index)
    category_id  = (index == 0) ? category_ids.select{|e| e[-1] == data.text.sub(':','')}.flatten.first : category_ids.select{|e| e[-1] == all_headers[index]}.flatten.first
    data_hash = {}
    data_hash[:business_categ_id]= business_category
    data_hash[:hurricane_id] = hurricane_id
    data_hash[:data_categ_id] = category_id
    data_hash[:value] = (data.text.include? 'Total Estimated Insured Losses') ? data.next_sibling.text.gsub(/[$,]/,"").squish : data.text.gsub(',','').squish
    data_hash[:value_unit] = (data.text.include? 'Total Estimated Insured Losses') ? ((data.next_sibling.text.include? '$') ? '$' : nil) : ((data.text.include? "%") ? "%" : nil)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://www.floir.com/Office/HurricaneSeason/#{url}"
    data_hash[:run_id]= run_id
    data_hash[:touched_run_id]= run_id
    data_hash
  end

  def general_data_category(data, url, run_id)
    data_hash = {}
    data_hash[:categ_desc] = data.text.squeeze(" ").strip.gsub("\n","").gsub("\r"," ").sub(':','')
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = "https://www.floir.com/Office/HurricaneSeason/#{url}"
    data_hash[:run_id]= run_id
    data_hash[:touched_run_id]= run_id
    data_hash
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
