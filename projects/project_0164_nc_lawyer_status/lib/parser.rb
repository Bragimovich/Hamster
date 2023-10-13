class NorthCarolinaParser < Hamster::Parser

  DOMAIN = "https://portal.ncbar.gov"

  def get_profession(reponse)
    body_array = []
    document = Nokogiri::HTML(reponse.body.force_encoding("utf-8"))
    vg  = document.css("#__VIEWSTATEGENERATOR")[0]['value']
    ev  = document.css("#__EVENTVALIDATION")[0]['value']
    vs  = document.css("#__VIEWSTATE")[0]['value']
    btn = document.css("#btnSubmit")[0]['value']
    body_array.append(vg)
    body_array.append(vs)
    body_array.append(ev)
    body_array.append(btn)
    specialist_array = document.css("#ddSpecialization option")
    specialist_array.shift
    specialist_array = specialist_array.map{|s| s.text}
    body_array.append(specialist_array)
  end

  def get_lawyer_links(response)
    outer_page = Nokogiri::HTML(response.body.force_encoding("utf-8"))
    lawyers_links = outer_page.css("div.panel-body table.table tbody tr a").map{|e| DOMAIN+e["href"]}
    lawyers_links = lawyers_links.reject {|e| e.split('=').last == '0'}
  end

  def get_inner_links(content)
    document      = Nokogiri::HTML(content.force_encoding("utf-8"))
    lawyers_links = document.css("div.panel-body table.table tbody tr a").map{|e| DOMAIN+e["href"]}
  end

  def lawyers_info_parser(response, link, run_id)
    document          = Nokogiri::HTML(response.force_encoding("utf-8"))
    titles            = document.css("div.row dt").map{|e| e.text.downcase.strip}
    values            = document.css("div.row  dd").map{|e| e.text.strip}
    bar_number        = search_value(titles,values,"bar #:")
    name              = search_value(titles,values,"name:") rescue nil
    law_firm_city     = search_value(titles,values,"city:") 
    law_firm_state    = search_value(titles,values,"state:") 
    law_firm_zip      = search_value(titles,values,"zip code:") 
    phone             = search_value(titles,values,"work phone:") rescue nil
    email             = search_value(titles,values,"email:") rescue nil
    status            = search_value(titles,values,"status:")
    sections          = search_value(titles,values,"board certified in:")
    judicial_district = search_value(titles,values,"judicial district:")
    date_admitted     = Date.strptime(search_value(titles,values,"date admitted:"),"%m/%d/%Y").to_s  rescue nil
    status_date       = Date.strptime(search_value(titles,values,"status date:"),"%m/%d/%Y").to_s  rescue nil
    law_firm_name     = nil
    law_firm_address  = nil
    name_prefix,first_name, middle_name ,last_name = fetch_name(name)
    document.css("div.row dt").each_with_index do |dt, index|
      if (dt.text.include? "Address")
        add = document.css("div.row dd")[index]
        (add.children[0].text.count("0-9") > 0)? law_firm_name = nil : law_firm_name = add.children[0].text
        law_firm_address = (law_firm_name.nil?)? add.children.map {|e| e.text.squish}.reject{|r| r.empty?}.join("\n") : add.children[1..].map {|e| e.text.squish}.reject{|r| r.empty?}.join("\n")
      end
    end
    lawyer_data_hash = {}
    lawyer_data_hash[:link]              = link
    lawyer_data_hash[:bar_number]        = bar_number
    lawyer_data_hash[:name]              = name rescue nil
    lawyer_data_hash[:status]            = status.split("\t")[0].strip rescue nil
    lawyer_data_hash[:law_firm_name]     = law_firm_name rescue nil
    lawyer_data_hash[:law_firm_city]     = clean_city(law_firm_city)
    lawyer_data_hash[:law_firm_zip]      = law_firm_zip
    lawyer_data_hash[:law_firm_address]  = clean_address(law_firm_address, law_firm_city, law_firm_zip, law_firm_state)
    lawyer_data_hash[:law_firm_state]    = law_firm_state
    lawyer_data_hash[:email]             = email
    lawyer_data_hash[:phone]             = phone
    lawyer_data_hash[:sections]          = sections
    lawyer_data_hash[:judicial_district] = judicial_district
    lawyer_data_hash[:date_admitted]     = date_admitted
    lawyer_data_hash[:status_date]       = status_date
    lawyer_data_hash[:md5_hash]          = create_md5_hash(mark_empty_as_nil(lawyer_data_hash))
    lawyer_data_hash[:name_prefix]       = name_prefix
    lawyer_data_hash[:first_name]        = first_name
    lawyer_data_hash[:middle_name]       = middle_name
    lawyer_data_hash[:last_name]         = last_name
    lawyer_data_hash[:run_id]            = run_id
    lawyer_data_hash[:data_source_url]   = "https://portal.ncbar.gov/Verification/results.aspx"
    lawyer_data_hash = mark_empty_as_nil(lawyer_data_hash)
    lawyer_data_hash
  end

  private

  def clean_city(law_firm_city)
    city = law_firm_city.split(',')[0].tr("0-9", "") rescue nil
    (city.end_with? '-') ?  city[..-2] : city
  end

  def clean_address(address, city, zip, state)
    address.gsub(/#{city}|#{state}|#{zip}/, '').squish rescue nil
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "null") ? nil : value}
  end

  def search_value(titles, values, word)
    value = nil
    titles.each_with_index do |title, idx|
      if title == word
        value  = values[idx]
        break
      end
    end
    value
  end

  def fetch_name(name)
    prefixs = ["Mr.", "Ms.", "Judge", "Mrs.", "Ms", "Dr.", "Rev.", "Miss"]
    arr = name.split(" ") rescue nil
    return [] if arr.nil?
    (prefixs.include? arr[0])? prefix_name = arr.delete_at(0) : prefix = nil
    first_name = arr.delete_at(0) rescue nil
    middle_name = arr.delete_at(0) if arr.count > 1 rescue nil
    last_name = arr.join(" ").strip
    [prefix_name, first_name, middle_name, last_name]
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end

end
