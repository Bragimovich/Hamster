# frozen_string_literal: true

class Parser < Hamster::Parser

  def get_access_token(response)
    data = Nokogiri::HTML(response.body)
    data_hash = {}
    data_hash = {
      data_sitekey: data.xpath("//div[@class='g-recaptcha']//@data-sitekey").first.content,
      token: data.xpath("//form[@id='offenderObj']//input[@name='CSRFToken']/@value").text
    }
    return data_hash
  end

  def fetch_table_data(tbody_1,id)
    tbody_arr = []
    tbody_1.each do |tr|
      tbody_hash = {}
      tbody_hash[:number] = id
      tbody_hash[:last_name] = tr.children[1].text.split(",")[0].gsub("&nbsp"," ")
      middle_name_check = tr.children[1].text.split(",")[1].gsub("&nbsp"," ").split(" ")
      if middle_name_check.count > 1
        tbody_hash[:first_name] = middle_name_check[0].gsub(" ", "")
        tbody_hash[:middle_name] = middle_name_check[1].gsub(" ", "")
        tbody_hash[:full_name] = tbody_hash[:first_name] +  " " +  tbody_hash[:middle_name] + " " + tbody_hash[:last_name]
      else
        tbody_hash[:first_name] = tr.children[1].text.split(",")[1].gsub("&nbsp"," ").gsub(" ","")
        tbody_hash[:full_name] = tbody_hash[:first_name] + " " + tbody_hash[:last_name]
      end
      birth_date = tr.children[3].text
      tbody_hash[:birth_date] = Date.strptime(birth_date, "%m/%d/%Y")
      tbody_hash[:age] = Time.now.year - tbody_hash[:birth_date].year
      tbody_hash[:alias] = tr.children[5].text
      tbody_arr << tbody_hash
      tbody_arr
    end
    tbody_arr
  end

  def fetch_booking(doc2)

    second_table = doc2.css('body').css('div#masthead').css('#two_of_3').css('table').css('tr')
    second_table_arr = []
    second_table[1..-1].each do |tr,doc1|
      second_table_hash = {}
      second_table_hash[:status] = tr.css('td')[0].text
      second_table_hash[:booking_date] = tr.css('td')[1].text
      second_table_hash[:release_date] = tr.css('td')[2].text
      second_table_hash[:next_court_date] = tr.css('td')[3].text
      second_table_hash[:court_name] = tr.css('td')[4].text
      second_table_arr << second_table_hash
      second_table_arr
    end
    second_table_arr
  end

  def fetch_details(doc2)
    
    third_table = doc2.css('body').css('div#masthead').css('#three_of_3').css('table').css('tr')
    third_table_arr = []
    third_table[1..-1].each do |tr|
      third_table_hash = {}
      third_table_hash[:court_name] = tr.css('td')[0].text
      third_table_hash[:court_type] = tr.css('td')[1].text
      third_table_hash[:planned_release_date] = tr.css('td')[2].text
      third_table_hash[:court_date] = tr.css('td')[3].text
      third_table_hash[:bond_amount] = tr.css('td')[4].text
      third_table_hash[:name] = tr.css('td')[5].text.split("-")[1].gsub(" ","")
      third_table_hash[:case] = tr.css('td')[5].text.split("-")[0].gsub(" ","")
      third_table_arr << third_table_hash
      third_table_arr
    end
    third_table_arr
  end

  def fetch_booking_number(doc1)   
    booking_number = doc1.css('body').css('div#masthead').css('tbody')[1].css('td')[0].text.strip
  end
  
end
