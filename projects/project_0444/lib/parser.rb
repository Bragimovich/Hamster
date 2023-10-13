# frozen_string_literal: true

require_relative '../lib/scraper'

class Parser < Hamster::Parser
  def get_csv_data(source)
    json = (Nokogiri::HTML source.body).text
    JSON.parse(json)['data']
  end

  def parse(csv_path)
    prefix = Time.now.to_s.split[0]
    suffix = 'USA'
    path = "#{storehouse}store/#{prefix}-#{suffix}.pdf"
    reader = PDF::Reader.new(path)
    text = ''
    reader.pages.each { |page| text += "\n\n   #{page.text}" }

    date_part = text.split('Data as of')[1]
    if !date_part
      puts "PDF is empty, can't parse data"
      exit 1
    end
    updated = DateTime.parse(date_part.split('Eastern')[0])

    table = text.split("Cases\n\n\n")[1].split('Data as of')[0].split("\n\n")
    total = 0
    cases_data = []
    table.each do |row|
      state = row.split[0..-2].join(' ') # 'District Of Columbia' catching
      cases = row.split[-1]
      next if !cases # ignore empty lines in PDF
      total += cases.to_i

      cases_data << {
        state:    state,
        cases:    cases,
        time:     time,
        date:     date,
        csv:      csv_path,
        updated:  updated
      }
    end
    puts ['*'*77, 'Total cases -=> ', total]
    cases_data
  end

  def parse_csv(csv_path)
    arr_of_arrs = []
    begin
      arr_of_arrs = CSV.read(csv_path)[1..-2]
    rescue
      puts '*'*77, "No CSV file..."
    end
    cases_data = []
    arr_of_arrs.each do |row|
      date_part = row[-1][11..-5]
      updated = DateTime.parse(date_part)
      time_now = Time.now
      time = Time.at(time_now.to_i % DAY)
      date = Time.at(time_now.to_i / DAY * DAY)

      cases_data << {
        state:    row[0],
        cases:    row[1],
        time:     time,
        date:     date,
        csv:      csv_path,
        updated:  updated
      }
    end
    total = cases_data.map {|el| el[:cases].to_i}.sum
    puts ['*'*77, 'Total cases -=> ', total]
    cases_data
  end
end
