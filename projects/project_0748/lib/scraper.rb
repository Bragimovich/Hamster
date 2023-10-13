class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def mechanize_con
    @cobble = Dasher.new(:using=>:cobble)
  end

  def fetch_image(link)
    @cobble.get(link)
  end

  def main_page
    connect_to("https://web.mo.gov/doc/offSearchWeb/", ssl_verify: false)
  end

  def captcha_request(captcha_image_url, cookie, retries = 50)
    begin
      uri = URI.parse("https://web.mo.gov/doc/offSearchWeb/captcha")
      request = Net::HTTP::Get.new(uri)
      request["Authority"] = "web.mo.gov"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["Cookie"] = cookie
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      proxy_ip, proxy_port = fetch_proxies
      response = Net::HTTP.SOCKSProxy(proxy_ip, proxy_port).start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue => exception
      raise if retries < 1
      captcha_request(captcha_image_url, cookie, retries - 1)
    end
  end

  def welcome_post_req(captcha_text, cookie)
    connect_to(url: "https://web.mo.gov/doc/offSearchWeb/welcome.do", headers: welcome_headers(cookie) ,req_body: ready_post_req(captcha_text), method: :post)
  end

  def second_get_req(cookie)
    connect_to(url: "https://web.mo.gov/doc/offSearchWeb/searchOffenderAction.do", headers: welcome_headers(cookie))
  end

  def names_post_req(fname,lname,cookie)
    connect_to(url: "https://web.mo.gov/doc/offSearchWeb/searchOffenderAction.do", headers: welcome_headers(cookie) ,req_body: ready_names_post_req(fname,lname), method: :post)
  end

  def names_get_req(cookie)
    connect_to(url: "https://web.mo.gov/doc/offSearchWeb/offenderListAction.do", headers: welcome_headers(cookie))
  end

  def get_inner_link_page(link, cookie)
    connect_to(url: link, headers: welcome_headers(cookie))
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

  def ready_post_req(captcha_text)
    "captcha=#{CGI.escape captcha_text}&subType=Proceed+to+Offender+Web+Search"
  end

  def fetch_proxies
    proxy = PaidProxy.all.to_a.shuffle.first
    proxy_ip, proxy_port = proxy["ip"], proxy["port"]
    [proxy_ip, proxy_port]
  end

  def welcome_headers(cookie)
    {
      "Content_Type" => "application/x-www-form-urlencoded",
      "Authority" => "web.mo.gov",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cookie" => cookie,
      "Origin" => "https://web.mo.gov",
      "Referer" => "https://web.mo.gov/doc/offSearchWeb/",
    }
  end

  def ready_names_post_req(fname,lname)
    "docId=&subType=Search&firstName=#{fname}&lastName=#{lname}"
  end

end
