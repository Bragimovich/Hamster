require_relative '../lib/parser'
class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @parser = Parser.new
  end

  def get_first_page(site, option, status, letter)
    site = site.split('_').join('-')
    referer =  "https://eapps.courts.state.va.us/#{site}/caseInquiry/commonInquiry"
    headers = get_headers
    headers = headers.merge({"Referer": referer})
    body = get_body(status,letter,option)
    url = "https://eapps.courts.state.va.us/#{site}/caseInquiry/commonInquiry"
    connect_to(url: url, headers:headers, req_body:body, method: :post)
  end

  def get_outer_page(response, cookie)
    headers = get_headers
    headers = headers.merge({"Cookie": cookie})
    url = parser.get_next_page_url(response)
    connect_to(url: url, headers:headers, method: :get)
  end

  def get_inner_page(url)
    url = "https://eapps.courts.state.va.us"+url
    connect_to(url:url)
  end
  
  private

  attr_accessor :parser

  def get_headers
    {
      "Origin" => "https://eapps.courts.state.va.us",
      "Referer" => "https://eapps.courts.state.va.us/acms-public/caseInquiry/commonInquiry",
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

  def get_body(status, letter, party)
    "totalSize=30&inquiryType=&performSearch=performSearch&searchType=Case&partyType=#{party}&searchName=#{letter}&status=#{status}&caseType=&tribunal=&lowerTribunalNumber=&commonInquiry=Search"
  end
end
