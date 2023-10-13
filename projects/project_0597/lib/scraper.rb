# frozen_string_literal: true
class Scraper <  Hamster::Scraper::Dasher

  def api_call(offset, year, department)
    connect_to(url: "https://openpayroll.ct.gov/api/all_employees_records.json?limit=5000&offset=#{offset}&org1=#{department.gsub(" ","+")}&search_hash=%7B%7D&sort=desc&sort_field=&year=#{year}")
  end

  def get_departments(year)
    connect_to(url: "https://openpayroll.ct.gov/api/top_departments.json?limit=100&page=0&year=#{year}")
  end

  private
  
  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = response&.status
    puts status == 200 ? status.to_s.greenish : status.to_s.red
    puts '=================================='.yellow
  end

end
