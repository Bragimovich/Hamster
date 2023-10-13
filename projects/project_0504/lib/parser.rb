# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML doc
  end

  def crime_data
    arr = Array.new
    table = @html.css("div[id='footable_parent_1561']").css('table').css('tbody')
    table.css('tr').each do |tr|
      unless tr.css('td').text.empty?
        date = tr.css('td')[0].text.split('-')
        booking_date = Date.parse((date[2] + date[0] + date[1])).strftime("%Y-%m-%d")
        time = tr.css('td')[1].text
        number = tr.css('td')[2].text
        last_name = tr.css('td')[3].text
        first_name = tr.css('td')[4].text
        mname = tr.css('td')[5].text.present? ? tr.css('td')[5].text : nil

        if mname.nil?
          full_name = first_name +", "+ last_name
          middle_name = nil
        else
          full_name = first_name +", "+ mname +", "+last_name
          middle_name = mname
        end

        age = tr.css('td')[6].text
        race = tr.css('td')[7].text
        sex = tr.css('td')[8].text
        description = tr.css('td')[9].text.strip
        booking_agency = tr.css('td')[10].text
        data_source_url = "https://sheriff.tazewell-il.gov/inmate-lookup-c/"

        arr <<  {
          booking_date: booking_date,
          offense_date: booking_date,
          offense_time: time,
          detainee_id: number,
          last_name: last_name,
          first_name: first_name,
          middle_name: middle_name,
          full_name: full_name,
          age: age,
          race: race,
          sex: sex,
          description: description,
          booking_agency: booking_agency,
          data_source_url: data_source_url 
        }
      end
    end
    arr
  end
end
