# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML(doc)
  end

  def store_data
    salaries_arr = []
    table = @html.at('table tbody')
    return nil if table.nil?
    
    table.search('tr').each do |tr|
      cells = tr.search('th, td')
      salaries_arr << {
      year: cells[0].text.strip,
      name: cells[1].text.strip,
      gender: cells[2].text.strip,
      agency: cells[3].text.strip,
      city_county: cells[4].text.strip,
      classification: cells[5].text.strip,
      base_pay_end_of_fy: cells[6].text.strip,
      annual_gross_pay: cells[7].text.strip,
      travel: cells[8].text.strip
      }
    end
    salaries_arr
  end
end
