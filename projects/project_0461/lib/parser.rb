# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse(source)
    time_now = Time.now
    date = Time.at(time_now.to_i / DAY * DAY)
    prefix = date.to_s.split[0]
    csv = "epdata #{prefix}-World.csv"

    page = Nokogiri::HTML(source.body)
    subtitle = page.text.split('","Text')[0].split('":"')[-1]
    ES_MONTH.each_index { |i| subtitle.sub!(ES_MONTH[i], EN_MONTH[i]) }
    updated = DateTime.parse(subtitle.gsub(' de ', ' '))

    table = JSON.parse("[{\""+ page.text.split('[{"')[-1].split('}]')[0]+"}]")
    # puts data.map { |el| "#{el.to_a[4][1]} -=> #{el.to_a[7][1].to_i}" }

    total = 0
    cases_data = []
    table.each do |row|
      country = row["ValorTick"]
      cases = row["ValorEjeUnidad"].to_i
      total += cases
      time_now = Time.now
      date = Time.at(time_now.to_i / DAY * DAY)
      time = Time.at(time_now.to_i % DAY)
      cases_data << {
        country:  country,
        cases:    cases,
        time:     time,
        date:     date,
        csv:      csv,
        updated:  updated
      }
    end
    puts ['*'*77, "Total cases -=> ", total]
    cases_data
  end

end
