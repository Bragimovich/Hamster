class Parser
  def get_all_hrefs_of_outer_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    parsed_page.xpath("//div[@class='DnnModule DnnModule-DNN_HTML DnnModule-1610']//a")
  end

  def get_inner_url_from_dom(file_content)
    file_content.to_s.match(/\/data.+NOCACHE.+\"/)
  end

  def get_all_schools(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    all_schools_xpath = "/html/body[1]/p[@class='nospace']/a"
    parsed_page.xpath(all_schools_xpath)
  end

  def get_address(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    address_array = parsed_page.xpath("//p[@class='nospace']")[1..-1]&.take_while {|x| x.text.squish.length > 1 }
    city, state, zip = nil, nil, nil, nil
    hash = {}
    unless address_array.nil?
      city_state_zip = address_array&.last&.text&.squish
      if city_state_zip.present?
        city, state_zip = city_state_zip.split(",")
        state, zip = state_zip&.split(" ")
      end
      
      temp = []
      parsed_page.xpath("/html/body/p")[1+address_array&.count+1..-1].each do |p|
        temp << p&.text&.encode("UTF-8", invalid: :replace, replace: "")&.squish
        break if p&.next&.next&.name == "h3"
      end
  
      hash = parse_text_into_key_values(temp)
    end

    address1 = address_array&.first&.text&.squish
    address1&.gsub!("(Google map, other maps)",'')
    {
      year: Date.today.year,
      name: parsed_page.xpath("//p[@class='nospace b']")&.text&.encode("UTF-8", invalid: :replace, replace: "")&.squish,
      address1: address1&.squish,
      city: city&.gsub(",","")&.gsub(".",""),
      state: state,
      zip: zip,
      phone: hash['Phone'],
      fax: hash['Fax'],
      website: hash['School Web Site'],
      enrollment: hash['Enrollment'],
      nicknames: hash['Nickname(s)'],
      colors: hash['Colors'],
      school_type: hash['School Type'],
      county: hash['County'],
      cities_in_district: hash['Cities in District'],
      board_division: hash['Board Division'],
      legislative_division: hash['Legislative District']
    }
  end

  def parse_text_into_key_values(list)
    hash = {}
    list.each do |l|
      if l.present?
        key, value = l.split(":")
        if l.include?("Board Division")
          _list = l.split(",")
          _list.each do |t|
            key,value = t.split(":")
            hash[key.squish] = value&.squish
          end
        else
          hash[key] = value&.squish
        end
      end
    end
    hash
  end

  def get_all_divison(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    parsed_page.xpath("/html/body/h3").map(&:text).map(&:squish)
  end

  def get_school_directors(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    index = 0
    parsed_page.xpath("/html/body").first.children.each do |div|
      if div.name == "h3"
        break
      else
        index += 1
      end
    end
    temp = []
    temp_list = []
    parsed_page.xpath("/html/body").first.children[index..-1].each do |div|
      if div.name == "h3"
        temp << temp_list if temp_list.present?
        temp_list = []
        div_text = div&.text&.encode("UTF-8", invalid: :replace, replace: "")&.squish
        temp_list.append(div_text) if div_text != ""
      else
        div_text = div&.text&.encode("UTF-8", invalid: :replace, replace: "")&.squish
        temp_list.append(div_text) if div_text != ""
      end
    end
    temp << temp_list if temp_list.present?
  end

  def parse_school_directors(list)
    list_of_hashes = []
    list[1..-1].each do|l|
      title, full_name_website = l.split(":")

      email_regex = /\w+@.*\.\w{1,}/
      phone_number_regex = /\d+\-\d+-\d+/
      email, phone_number = nil, nil

      full_name_website.squish.split(" ").each do |s|
        if s.match(email_regex).to_s.present?
          email = s
        end

        if s.match(phone_number_regex).to_s.present?
          phone_number = s.match(phone_number_regex).to_s
        end
      end

      splits = full_name_website.squish.split(" ")
      full_name = []
      splits.each do |s|
        if s == email or s == phone_number or s == "phone"
          break
        else
          full_name << s
        end
      end

      first_name, middle_name, last_name = nil, nil, nil
      if full_name.length == 2
        # first_name and last name
        first_name = full_name.first
        last_name = full_name.last
      elsif full_name.length == 3
        # first , middle , last_name
        first_name = full_name.first
        last_name = full_name.last
        middle_name = full_name[1]
      end

      hash = {
        year: Date.today.year,
        title: title.squish,
        full_name: full_name.join(" "),
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name,
        email: email,
        phone_number: phone_number
      }
      list_of_hashes << hash
    end
    list_of_hashes
  end

  def get_all_sports(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = '/html/body/h2'
    parsed_page.xpath(xpath).map(&:text).map(&:squish)
  end

  def get_all_tables(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = '/html/body/table'
    tables = parsed_page.xpath(xpath)
    hash = {}
    tables.each do |table|
      sport_name = table&.previous_sibling&.previous_sibling&.text&.squish
      hash[sport_name] = table
    end
    hash
  end

  def parse_sports_table(table)
    all_rows = table.css('tr')
    list_of_hashes = []
    all_rows[2..-1].each do |row|
      td = row.children.select{|x| x&.name == "td"}
      hash = {
        host_school_name: td[0]&.text&.squish,
        opponent_school_name: td[1]&.text&.squish,
        coops_end: td[2]&.text&.squish
      }
      list_of_hashes << hash
    end
    list_of_hashes
  end

end