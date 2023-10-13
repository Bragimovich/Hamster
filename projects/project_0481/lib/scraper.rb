class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_search_page
    url = 'https://www.appeals2.az.gov/ODSPlus/caseInfo.cfm'
    connect_to(url: url, method: :get)
  end

  def get_outer_page(year, code, response)
    headers = get_headers
    body    = get_body(year, code)
    cookie  = response.headers['set-cookie']
    headers = headers.merge({"Cookie": cookie})
    url     = 'https://www.appeals2.az.gov/ODSPlus/caseInfo2.cfm'
    connect_to(url: url, headers:headers, req_body:body, method: :post)
  end

  def get_inner_page(url)
    url = "https://www.appeals2.az.gov/ODSPlus/#{url}"
    connect_to(url:url)
  end
  
  private

  def get_headers
    {
      "Origin" => "https://www.appeals2.az.gov",
      "Referer" => "https://www.appeals2.az.gov/ODSPlus/caseInfo.cfm",
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end

  def get_body(year, code)
    "CaseYear=#{year}&CaseNumber=&FilingDate=&CaseTitle=&TrialCourtCaseNumber=&searchverifycode=#{code}&Option=Search%26Select"
  end
end
