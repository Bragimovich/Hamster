# frozen_string_literal: true
class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML doc
  end

  def search_google_key
    key = @html.css('.g-recaptcha').attr("data-sitekey").text
    token = @html.css("input[name='__RequestVerificationToken']").attr("value").text
    {
      key: key,
      token: token
    }
  end

  def crime_data
    data_hash = Array.new
    @html.css("ul[class='inmatelist']").css('li').each do |li|
      charge_hash = {}
      article = li.css("article[class='inmate']")
      img_src = article.css('section').first.css('img').attr('src').text
      info = article.css('section')[1]

      name = info.css('h1').first.text
      age = info.css('h2').first.next_element.text
      race_sex = info.css('h2')[1].next_element.text
      race = race_sex.split('/')[0]
      sex = race_sex.split('/')[1]
      status = info.css("data[class='data-right']").first.text
      raw_date = info.css('h2')[2].next_element.text
      time = raw_date.split(' ').last(2).join(' ')
      date = raw_date.split(' ')[0].split('/')
      intake_date = Date.parse((date[2] + date[0] + date[1])).strftime("%Y-%m-%d")
      arrested_department = info.css('h2')[4].next_element.text
      charges = article.css('section')[2]
      charges.css('tr').each do |tr|
        if tr.css('td')[0].present?
          charge_hash[tr.css('td')[0].text] = tr.css('td')[1].text
        end
      end

      data_hash << {  
        full_name: name,
        original_link: img_src,
        age: age,
        race: race,
        sex: sex,
        status: status,
        booking_agency: arrested_department,
        arrest_date: intake_date,
        charge_hash: charge_hash
      }
    end
    data_hash
  end
end
