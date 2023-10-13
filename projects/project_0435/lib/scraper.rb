class Scraper <  Hamster::Scraper

  def call_api(offset)
    connect_to("https://datacatalog.cookcountyil.gov/resource/cjeq-bs86.json?$limit=10000&$offset=#{offset}")
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end

end
