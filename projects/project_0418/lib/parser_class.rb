require 'scylla'

class ParserClass
  BASE_URL = "https://www.fbi.gov/news/press-releases"

  def footer_topic_div(file_content)
    parsed_article_page = Nokogiri::HTML(file_content)
    footers = parsed_article_page.xpath('/html/body/div[2]/div[2]/div/article/div[1]/div[4]/div')    
    footers.each do |footer|
      if footer.text.include?('Topic(s):')
        return [true,footer]
      end
    end
    [false,""]
  end
  
  def footer_component_div(file_content)
    parsed_article_page = Nokogiri::HTML(file_content)
    footers = parsed_article_page.xpath('/html/body/div[2]/div[2]/div/article/div[1]/div[4]/div')    
    footers.each do |footer|
      if footer.text.include?('Component(s):')
        return [true,footer]
      end
    end
    [false,""]
  end

  def component_parse(footer,article_link)
    all_components = footer.xpath('div[2]/div')
    r_all_components = []
    all_components.each do |component|
      data_hash = {
        article_link: article_link,
        bureau_office: component.text
      }
      r_all_components.push(data_hash)
    end
    r_all_components
  end
   
  def topic_parse(footer ,article_link)
    all_topics = footer.xpath('div[2]/div')
    r_all_tags = []
    all_topics.each do |topic|
      hash = {
        "tag": topic.text
      }
      r_all_tags.push(hash)
    end
    r_all_tags
  end

  def parse_inner_div(inner_div)
    date = inner_div.text.match(/\d{1,2}\.\d{1,2}\.\d{4}/)[0]
    title = inner_div.text.gsub(/\d{1,2}\.\d{1,2}\.\d{4}/,'').gsub("\n","")
    link = inner_div.xpath('div/div[2]/p/a/@href')[0].value.to_s
    parsed_Date = Date.strptime(date, "%m.%d.%Y")
    {date: parsed_Date , title: title ,link: link}
  end

  def get_article_link_from_inner_div(inner_div)
    inner_div.xpath('div/div[2]/p/a/@href')[0].value.to_s
  end

  def get_inner_divs(file_content)
    parse_page = Nokogiri::HTML(file_content)
    all_divs_xpath = "//div[@class='query-results pat-pager']/ul/li"
    parse_page.xpath(all_divs_xpath)
  end

  def get_next_link(file_content)
    parse_page = Nokogiri::HTML(file_content)
    load_more_button_xpath = "//div[@class='query-results pat-pager']/p/button/@href"
    parse_page.xpath(load_more_button_xpath).to_s
  end

  def parse_teaser(first_paragraph)
    return "" if first_paragraph.nil?
    
    teaser = ""

    if first_paragraph.present?
      if first_paragraph.length > 600
        teaser = first_paragraph
        while true
          teaser = teaser.split('.')[1..-2].join(".")
          if teaser.length <= 600
            break
          end
        end
      else
        teaser = first_paragraph
      end
    end
    teaser
  end

  def parse_city_and_state(city_state)
    city , state = "" , ""
    
    if city_state != ""
      city_state_ =  city_state&.split("–")
      
      if city_state_&.length != 1 
        city ,state_prime = city_state_&.first&.split(',')
      else
        splits = city_state&.split(":")
        if splits&.length != 1
          city ,state_prime = splits&.first&.split(',')
        end
      end
      
      if city != nil and city&.length > 20
        city = ""
      end
    end
    
    us_states = ['Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut', 'Washington DC', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming']
    if state_prime != nil
      us_states.each do |s|
        if state_prime&.downcase&.include?(s.downcase)
          state = s
        end
      end

      if state == nil
        # check for substrings
        states.each do |s|
          # get only characters regex
          state_temp = state_prime&.scan(/[a-zA-Z]/)&.join("")
          if s.downcase.include?(state_temp)
            state = s
          end
        end
      end
    end

    r_city = nil
    city_names = ["Aberdeen", "Abilene", "Akron", "Albany", "Albuquerque", "Alexandria", "Allentown", "Amarillo", "Anaheim", "Anchorage", "Ann Arbor", "Antioch", "Apple Valley", "Appleton", "Arlington", "Arvada", "Asheville", "Athens", "Atlanta", "Atlantic City", "Augusta", "Aurora", "Austin", "Bakersfield", "Baltimore", "Barnstable", "Baton Rouge", "Beaumont", "Bel Air", "Bellevue", "Berkeley", "Bethlehem", "Billings", "Birmingham", "Bloomington", "Boise", "Boise City", "Bonita Springs", "Boston", "Boulder", "Bradenton", "Bremerton", "Bridgeport", "Brighton", "Brownsville", "Bryan", "Buffalo", "Burbank", "Burlington", "Cambridge", "Canton", "Cape Coral", "Carrollton", "Cary", "Cathedral City", "Cedar Rapids", "Champaign", "Chandler", "Charleston", "Charlotte", "Chattanooga", "Chesapeake", "Chicago", "Chula Vista", "Cincinnati", "Clarke County", "Clarksville", "Clearwater", "Cleveland", "College Station", "Colorado Springs", "Columbia", "Columbus", "Concord", "Coral Springs", "Corona", "Corpus Christi", "Costa Mesa", "Dallas", "Daly City", "Danbury", "Davenport", "Davidson County", "Dayton", "Daytona Beach", "Deltona", "Denton", "Denver", "Des Moines", "Detroit", "Downey", "Duluth", "Durham", "El Monte", "El Paso", "Elizabeth", "Elk Grove", "Elkhart", "Erie", "Escondido", "Eugene", "Evansville", "Fairfield", "Fargo", "Fayetteville", "Fitchburg", "Flint", "Fontana", "Fort Collins", "Fort Lauderdale", "Fort Smith", "Fort Walton Beach", "Fort Wayne", "Fort Worth", "Frederick", "Fremont", "Fresno", "Fullerton", "Gainesville", "Garden Grove", "Garland", "Gastonia", "Gilbert", "Glendale", "Grand Prairie", "Grand Rapids", "Grayslake", "Green Bay", "GreenBay", "Greensboro", "Greenville", "Gulfport-Biloxi", "Hagerstown", "Hampton", "Harlingen", "Harrisburg", "Hartford", "Havre de Grace", "Hayward", "Hemet", "Henderson", "Hesperia", "Hialeah", "Hickory", "High Point", "Hollywood", "Honolulu", "Houma", "Houston", "Howell", "Huntington", "Huntington Beach", "Huntsville", "Independence", "Indianapolis", "Inglewood", "Irvine", "Irving", "Jackson", "Jacksonville", "Jefferson", "Jersey City", "Johnson City", "Joliet", "Kailua", "Kalamazoo", "Kaneohe", "Kansas City", "Kennewick", "Kenosha", "Killeen", "Kissimmee", "Knoxville", "Lacey", "Lafayette", "Lake Charles", "Lakeland", "Lakewood", "Lancaster", "Lansing", "Laredo", "Las Cruces", "Las Vegas", "Layton", "Leominster", "Lewisville", "Lexington", "Lincoln", "Little Rock", "Long Beach", "Lorain", "Los Angeles", "Louisville", "Lowell", "Lubbock", "Macon", "Madison", "Manchester", "Marina", "Marysville", "McAllen", "McHenry", "Medford", "Melbourne", "Memphis", "Merced", "Mesa", "Mesquite", "Miami", "Milwaukee", "Minneapolis", "Miramar", "Mission Viejo", "Mobile", "Modesto", "Monroe", "Monterey", "Montgomery", "Moreno Valley", "Murfreesboro", "Murrieta", "Muskegon", "Myrtle Beach", "Naperville", "Naples", "Nashua", "Nashville", "New Bedford", "New Haven", "New London", "New Orleans", "New York", "New York City", "Newark", "Newburgh", "Newport News", "Norfolk", "Normal", "Norman", "North Charleston", "North Las Vegas", "North Port", "Norwalk", "Norwich", "Oakland", "Ocala", "Oceanside", "Odessa", "Ogden", "Oklahoma City", "Olathe", "Olympia", "Omaha", "Ontario", "Orange", "Orem", "Orlando", "Overland Park", "Oxnard", "Palm Bay", "Palm Springs", "Palmdale", "Panama City", "Pasadena", "Paterson", "Pembroke Pines", "Pensacola", "Peoria", "Philadelphia", "Phoenix", "Pittsburgh", "Plano", "Pomona", "Pompano Beach", "Port Arthur", "Port Orange", "Port Saint Lucie", "Port St. Lucie", "Portland", "Portsmouth", "Poughkeepsie", "Providence", "Provo", "Pueblo", "Punta Gorda", "Racine", "Raleigh", "Rancho Cucamonga", "Reading", "Redding", "Reno", "Richland", "Richmond", "Richmond County", "Riverside", "Roanoke", "Rochester", "Rockford", "Roseville", "Round Lake Beach", "Sacramento", "Saginaw", "Saint Louis", "Saint Paul", "Saint Petersburg", "Salem", "Salinas", "Salt Lake City", "San Antonio", "San Bernardino", "San Buenaventura", "San Diego", "San Francisco", "San Jose", "Santa Ana", "Santa Barbara", "Santa Clara", "Santa Clarita", "Santa Cruz", "Santa Maria", "Santa Rosa", "Sarasota", "Savannah", "Scottsdale", "Scranton", "Seaside", "Seattle", "Sebastian", "Shreveport", "Simi Valley", "Sioux City", "Sioux Falls", "South Bend", "South Lyon", "Spartanburg", "Spokane", "Springdale", "Springfield", "St. Louis", "St. Paul", "St. Petersburg", "Stamford", "Sterling Heights", "Stockton", "Sunnyvale", "Syracuse", "Tacoma", "Tallahassee", "Tampa", "Temecula", "Tempe", "Thornton", "Thousand Oaks", "Toledo", "Topeka", "Torrance", "Trenton", "Tucson", "Tulsa", "Tuscaloosa", "Tyler", "Utica", "Vallejo", "Vancouver", "Vero Beach", "Victorville", "Virginia Beach", "Visalia", "Waco", "Warren", "Washington", "Waterbury", "Waterloo", "West Covina", "West Valley City", "Westminster", "Wichita", "Wilmington", "Winston", "Winter Haven", "Worcester", "Yakima", "Yonkers", "York", "Youngstown"]
    
    city_prime = city&.scan(/[a-zA-Z]/)&.join("")
    city_names.each do |c|
      if city_prime&.downcase&.include?(c.downcase)
        r_city = c
      end
    end
    
    # city is still nil 
    if r_city == nil
      city_names.each do |c|
        # without removing extra characters
        if city&.downcase&.include?(c.downcase)
          r_city = c
        end
      end
    end

    [r_city ,state]
  end

  def parse_contact_info(footers,file_content)
    contact_info = nil

    footers.each do |footer|
      if footer.text.include?('Contact:')
        contact_info = footer.inner_html
      end
    end

    # still nil then try another way on the page
    if contact_info == nil
      x_path = "//div[@class='field__item even']/p"
      article_divs = file_content.xpath(x_path)
      if article_divs&.first&.text&.include?("CONTACT:")
        contact_info = article_divs&.first.to_html
      end
    end

    contact_info
  end

  def parse_article(file_content,link)
    if link.include? "justice.gov"
      x_path = "//div[@class='field__item even']/p"
      article_divs = file_content.xpath(x_path)
      if article_divs&.first&.text&.include?("CONTACT:")
        first_paragraph = article_divs&.first(2)&.last
        [article_divs&.first&.parent&.children[1..-1]&.to_html , first_paragraph ,x_path]
      else
        if article_divs&.first&.text == ""
          first_paragraph = article_divs&.first(2)&.last
        else
          first_paragraph = article_divs&.first
        end
        [article_divs&.first&.parent&.to_html ,first_paragraph , x_path]
      end
    
    elsif link.include? "fbi.gov"
      x_path = "//*[@id='main-content']/div/div"
      article_divs = file_content.xpath(x_path)[2..-1]
      [article_divs.to_html ,article_divs[0],x_path]
    
    elsif link.include? "investor.gov"
      x_path = "div[class='article-body']"
      article_divs = file_content.xpath(x_path)
      [article_divs.to_html , article_divs&.first , x_path]

    elsif link.include? "cisa.gov"
      x_path = "//article"
      article_divs = file_content.xpath(x_path)
      first_paragraph = file_content.xpath("//article//p[1]")
      [article_divs.to_html , first_paragraph , x_path]
    end
  end

  def parse_inner_article(file_content,link)
    parsed_article_page = Nokogiri::HTML(file_content)

    return unless parsed_article_page.present?

    footers = parsed_article_page.xpath('/html/body/div[2]/div[2]/div/article/div[1]/div[4]/div')
    
    contact_info = parse_contact_info(footers , parsed_article_page)

    unless contact_info.present?
      contact_info = "N/A"
    end

    city  = ""
    state = ""
    
    full_article = ""
    
    article_not_in_english = true

    full_article , first_paragraph ,x_path = parse_article(parsed_article_page ,link)
    
    if link.include? "justice.gov"
      city,state = parse_city_and_state(first_paragraph&.text)
    end
    
    teaser = parse_teaser(first_paragraph&.text)

    dirty_news = false

    # checking the language of article
    if parsed_article_page.xpath(x_path)&.text&.language == "english"
      article_not_in_english = false
    end

    if full_article == "" or article_not_in_english
      dirty_news = true
    end

    { 
      teaser: teaser,
      article: full_article,
      country: 'US',
      state: state, 
      city: city,
      contact_info: contact_info,
      dirty_news: dirty_news
    }
  end

end
