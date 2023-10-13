class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def initialize
    start_browser
  end

  def start_browser
    @hammer = Dasher.new(using: :hammer, headless: true, proxy_filter: @proxy_filter)
    @browser = @hammer.connect
  end

  def main_page(url)
    connect_to(url: url, headers: headers, proxy_filter: @proxy_filter)
  end

  def main_request(f_name, l_name, cookie)
    url = "https://www.dpscs.state.md.us/inmate/search.do?searchType=name&firstnm=#{f_name}&lastnm=#{l_name}"
    final_headers = headers
    final_headers[:Cookie] = cookie
    connect_to(url: url, headers: final_headers, proxy_filter: @proxy_filter)
  end

  def pagination_request(f_name, l_name, start, cookie)
    url = "https://www.dpscs.state.md.us/inmate/search.do?searchType=name&lastnm=#{l_name}&firstnm=#{f_name}&start=#{start.to_s}"
    final_headers = headers
    final_headers[:Cookie] = cookie
    connect_to(url: url, headers: headers, proxy_filter: @proxy_filter)
  end

  def inner_link_request(link, cookie)
    final_headers = headers
    final_headers[:Cookie] = cookie
    connect_to(url: link , headers: final_headers, proxy_filter: @proxy_filter)
  end

  def facility_request(link)
    browser.go_to(link)
    waiting_until_element_found('#footer_block')
    browser.body
  end

  def close_browser
    hammer.close
  end

  private

  attr_accessor :browser, :hammer

  def headers
    {
     "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
     "Accept-Language" => "en-US,en;q=0.9",
     "Cache-Control" => "max-age=0",
     "Connection" => "keep-alive",
     "Sec-Fetch-Dest" => "document",
     "Sec-Fetch-Mode" => "navigate",
     "Sec-Fetch-Site" => "none",
     "Sec-Fetch-User" => "?1",
     "Upgrade-Insecure-Requests" => "1",
     "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
     "Sec-Ch-Ua" => "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
     "Sec-Ch-Ua-Mobile" => "?0",
     "Sec-Ch-Ua-Platform" => "\"Linux\"",
    }
  end

  def waiting_until_element_found(search)
    counter = 1
    element = element_search(search)
    while (element.nil?)
      element = element_search(search)
      sleep 2
      break unless element.nil?
      counter +=1
      break if (counter > 20)
    end
    element
  end

  def element_search(search)
    browser.at_css(search)
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

end
