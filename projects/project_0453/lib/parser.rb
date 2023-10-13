# frozen_string_literal: true

require_relative '../models/world_cases'

class Parser < Hamster::Parser

  def parse
    prefix = Time.now.to_s.split[0]
    path = Hamster::Scraper.new.storehouse + "store/" + "#{prefix}-World"

    text = PDF::Reader.new(path + ".pdf").pages.first.text
    updated = DateTime.parse(text.split("Data as of ")[1].split(" EDT")[0])

    text = PDF::Reader.new(path + "Table.pdf").pages.first.text
    table = text.split("Cases\n")[1].split("Total")[0].gsub("\n\n", "\n").split("\n")[1..-1]

    total = 0
    cases_data = []
    table.each do |row|
      country = row.split("    ")[0]
      cases = row.split("    ")[-1].to_i
      total += cases
      time_now = Time.now
      date = Time.at(time_now.to_i / DAY * DAY)
      time = Time.at(time_now.to_i % DAY)
      cases_data << {
        country:  country,
        cases:    cases,
        time:     time,
        date:     date,
        updated:  updated
      }
    end
    puts ['*'*77, "Total cases -=> ", total]
    cases_data
  end

end
