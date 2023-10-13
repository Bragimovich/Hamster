class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_outer_page(letter)
    url =  "https://www.coloradosupremecourt.com/Search/AttyResults.asp"
    body = get_body(letter)
    connect_to(url: url, headers:headers, req_body:body, method: :post)
  end

  def get_inner_page(url)
    connect_to(url:url)&.body
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

  def get_body(letter)
    "RegNum=&Lname=#{letter}&Fname=&Submit=Search"
  end

  def headers
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Connection" => "keep-alive",
      "Origin" => "https://www.coloradosupremecourt.com",
      "Referer" => "https://www.coloradosupremecourt.com/Search/AttSearch.asp",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-s" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36",
      "Sec-Ch-Ua" => "\".Not/A)Brand\";v=\"99\", \"Google Chrome\";v=\"103\", \"Chromium\";v=\"103\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\""
    }
  end
end
