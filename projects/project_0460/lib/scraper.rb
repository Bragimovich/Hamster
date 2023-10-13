require_relative '../lib/parser'

class Scraper < Hamster::Scraper

  HEADERS = {
    "Authority" => "www.supremecourt.ohio.gov",
    "Accept" => "*/*",
    "Accept-Language" => "en-US,en;q=0.9",
    "Origin" => "https://www.supremecourt.ohio.gov",
    "Referer" => "https://www.supremecourt.ohio.gov/AttorneySearch/",
    "Sec-Ch-Ua" => "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"100\", \"Google Chrome\";v=\"100\"",
    "Sec-Ch-Ua-Mobile" => "?0",
    "Sec-Ch-Ua-Platform" => "\"Linux\"",
    "Sec-Fetch-Dest" => "empty",
    "Sec-Fetch-Mode" => "cors",
    "Sec-Fetch-Site" => "same-origin",
    "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36",
    "X-Requested-With" => "XMLHttpRequest",
    }

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @parser = Parser.new
  end

  def token_generator
    token_page = connect_to("https://www.supremecourt.ohio.gov/AttorneySearch/")
    @parser.token(token_page)
  end
  
  def scraper(attorney_reg, header_token)
    header_token = HEADERS.merge({"x-csrf-token": header_token})
    body = "regNumber=#{attorney_reg}&action=GetAttyInfo&attyNumber=0&searchResults="
    connect_to("https://www.supremecourt.ohio.gov/AttorneySearch/Ajax.ashx", headers:header_token, req_body:body, method: :post, proxy_filter: @proxy_filter)&.body
  end

  private
  
  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block) 
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
end
