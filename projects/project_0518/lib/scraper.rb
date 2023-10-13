# frozen_string_literal: true
class Scraper < Hamster::Scraper

  URL = "https://eaccess.k3county.net/eservices/search.page.22"
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def landing_page
    connect_to(URL, headers: get_headers)
  end

  def redirect_using_id(x_value, cookie)
    form_data = 'id1_hf_0=&navigatorAppName=Netscape&navigatorAppVersion=5.0+%28X11%3B+Linux+x86_64%29+AppleWebKit%2F537.36+%28KHTML%2C+like+Gecko%29+Chrome%2F109.0.0.0+Safari%2F537.36&navigatorAppCodeName=Mozilla&navigatorCookieEnabled=true&navigatorJavaEnabled=false&navigatorLanguage=en-US&navigatorPlatform=Linux+x86_64&navigatorUserAgent=Mozilla%2F5.0+%28X11%3B+Linux+x86_64%29+AppleWebKit%2F537.36+%28KHTML%2C+like+Gecko%29+Chrome%2F109.0.0.0+Safari%2F537.36&screenWidth=1920&screenHeight=1080&screenColorDepth=24&utcOffset=5&utcDSTOffset=5&browserWidth=1920&browserHeight=547&hostname=eaccess.k3county.net'
    connect_to(url: "https://eaccess.k3county.net/eservices/#{x_value}", headers: set_cookie_and_origin(cookie), req_body: form_data, method: :post, proxy_filter: @proxy_filter) { |resp| resp.headers["location"]&.match?(%r{search.page}) }
  end

  def url_redirects(cookie)
    headers = set_cookie(cookie)
    connect_to(URL, headers: headers)
  end

  def captcha_request(captcha_image_url, cookie)
    captcha_url = URL + captcha_image_url
    headers = set_cookie(cookie)
    connect_to(captcha_url, headers: headers)
  end

  def  post_captcha_request(cookie, captcha_response, x_value, form_id)
    form_data = "iddb_hf_0=&captchaPanel%3AchallengePassword=#{captcha_response}&linkFrag%3AbeginButton=1"
    connect_to(url: "https://eaccess.k3county.net/eservices/home.page.4#{x_value}", headers: set_wicket_id_and_cookie(form_id, cookie), req_body: form_data, method: :post, proxy_filter: @proxy_filter)
  end

  def captcha_redirect(cookie, ajax_location)
    connect_to(url: "https://eaccess.k3county.net/eservices/#{ajax_location}", headers: set_cookie(cookie)) { |resp| resp.headers["location"]&.match?(%r{search.page}) }
  end

  def get_main_page(cookie, ajax_location)
    connect_to(url: "https://eaccess.k3county.net/eservices/#{ajax_location}", headers: set_cookie(cookie))
  end

  def increase_per_page_records_count(x_value, cookie, wicket_id)
    connect_to(url: "https://eaccess.k3county.net/eservices/#{x_value}", headers: set_wicket_id_and_cookie(wicket_id, cookie), req_body: "topSearchPanel%3ApageSize=2&", method: :post, proxy_filter: @proxy_filter)
  end

  def case_type_tab_selection(x_value, cookie, wicket_id)
    url = "https://eaccess.k3county.net/eservices/#{x_value}"
    headers = set_wicket_id_and_cookie(wicket_id, cookie)
    connect_to(url, headers: headers)
  end

  def date_value_request(x_value, cookie, date, date_string)
    connect_to(url: "https://eaccess.k3county.net/eservices/#{x_value}", headers: set_cookie_and_origin(cookie), req_body: "fileDateRange%3AdateInput#{date_string}=#{CGI.escape date}&", method: :post, proxy_filter: @proxy_filter)
  end

  def case_type_selection_request(x_value, cookie, wicket_id, case_type)
    connect_to(url: "https://eaccess.k3county.net/eservices/#{x_value}", headers: set_wicket_id_and_cookie(wicket_id, cookie), req_body: "#{case_type.gsub(' ', '%20')}&", method: :post, proxy_filter: @proxy_filter)
  end

  def  inner_method_request(x_value, cookie, case_type, start_date, end_date)
    form_data =  "ide9_hf_0=&fileDateRange%3AdateInputBegin=#{CGI.escape start_date}&fileDateRange%3AdateInputEnd=#{CGI.escape end_date}&caseCd=#{CGI.escape case_type}&statCd=+&ptyCd=+&submitLink=Search"
    connect_to(url: "https://eaccess.k3county.net/eservices/#{x_value}", headers: set_cookie_and_origin(cookie), req_body: form_data, method: :post, proxy_filter: @proxy_filter) { |resp| resp.headers["location"]&.match?(%r{searchresults.page}) }
  end

  def final_outer_page_request(cookie)
    connect_to(url: "https://eaccess.k3county.net/eservices/searchresults.page", headers: set_cookie(cookie))
  end

  def inner_page_request(x_value, cookie)
    connect_to(url: "https://eaccess.k3county.net/eservices/searchresults.page#{x_value}", headers: set_cookie_and_origin(cookie))
  end

  def pagination_request(x_value, cookie)
    connect_to(url: "https://eaccess.k3county.net/eservices/searchresults.page#{x_value[0]}", headers: set_wicket_id_and_cookie( x_value[1], cookie))
  end

  private

  def set_cookie(cookie)
    get_headers.merge({
      "Cookie" => cookie,
    })
  end

  def set_cookie_and_origin(cookie)
    get_headers.merge({
      "Cookie" => cookie,
      "Origin" =>"https://eaccess.k3county.net",
     })
  end

  def set_wicket_id_and_cookie(wicket_id, cookie)
    get_headers.merge({
      "Cookie" => cookie,
      "Origin" =>"https://eaccess.k3county.net",
      "Wicket-Ajax" => "true",
      "Wicket-Focusedelementid" => wicket_id
    })
  end

  def get_headers
    {
      "Authority" => "eaccess.k3county.net",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language" => "en-US,en;q=0.9",
      "Sec-Ch-Ua" => "\"Not_A Brand\";v=\"99\", \"Google Chrome\";v=\"109\", \"Chromium\";v=\"109\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"macOS\"",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "none",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36",
    }
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
    status = response&.status
    puts status == 200 ? status.to_s.greenish : status.to_s.red
    puts '=================================='.yellow
  end
end
