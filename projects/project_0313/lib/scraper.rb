
class Scraper < Hamster::Scraper

  def fetch_page(url)
    connect_to(url)
  end

  def fetch_api__data(agency_name, cookie)
    url = "https://salary.app.tn.gov/salary/search.json"
    connect_to(url: url, headers:headers(cookie), req_body:get_body(agency_name), method: :post)
  end

  private

  def get_body(agency_name)
    "{\"agencyName\":\"#{agency_name}\"}"
  end

  def headers(cookie)
    {
      "content-type" => "application/json;charset=UTF-8",
      "cookie" => "#{cookie}",
      "origin" => "https://salary.app.tn.gov",
      "referer" => "https://salary.app.tn.gov/public/searchsalary",
    }
  end

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
