require 'socksify/http'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end
  
  def main_page(court_type, year)
    url = (year==Date.today.year)? "https://legacy.utcourts.gov/opinions/#{court_type}/" : "https://legacy.utcourts.gov/opinions/#{court_type}/index-#{year}.asp"
    connect_to(url)
  end

  def pdf_response(link)
    connect_to(link)
  end

  def get_activity_page(cookie, main_page, two_captcha)
    form_value = main_page.css("#embedded").first["value"]
    link = main_page.css("div.form-group.text-center").first.css('img').first['src']
    captcha_image_url = "https://apps.utcourts.gov" + link
    response = fetch_image(captcha_image_url, cookie)
    c_p = two_captcha.decode(raw: response.body)
    sleep(2)
    landing_page(cookie, form_value, c_p)
  end

  def get_final_page(action_url, case_id, court_type, cookie)
    url = "https://apps.utcourts.gov#{action_url}"
    fetch_case(url, cookie, case_id, court_type)
  end

  private

  def landing_page(cookie_value, form_value, c_p, retries = 30)
    begin
      uri = URI.parse("https://apps.utcourts.gov/CourtsPublicWEB/LoginServlet")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/x-www-form-urlencoded"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["Cache-Control"] = "max-age=0"
      request["Connection"] = "keep-alive"
      request["Cookie"] = cookie_value
      request["Origin"] = "https://apps.utcourts.gov"
      request["Referer"] = "https://apps.utcourts.gov/CourtsPublicWEB/LoginServlet"
      request["Sec-Fetch-Dest"] = "document"
      request["Sec-Fetch-Mode"] = "navigate"
      request["Sec-Fetch-Site"] = "same-origin"
      request["Sec-Fetch-User"] = "?1"
      request["Upgrade-Insecure-Requests"] = "1"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
      request["Sec-Ch-Ua"] = "\"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"108\", \"Google Chrome\";v=\"108\""
      request["Sec-Ch-Ua-Mobile"] = "?0"
      request["Sec-Ch-Ua-Platform"] = "\"Linux\""
      request.set_form_data(
        "captchaEntry" => c_p.text,
        "embedded" => form_value,
        "mode" => "edit",
        "task" => "DOCKET",
        )

      req_options = {
        use_ssl: uri.scheme == "https",
      }
      proxy_ip, proxy_port = get_proxy
      response = Net::HTTP.SOCKSProxy(proxy_ip, proxy_port).start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue StandardError => e
      puts e
      raise if retries <= 1
      landing_page(cookie_value, form_value, c_p, retries - 1)
    end
  end

  def fetch_image(captcha_image_url, cookie_value, retries = 20)
    begin
      uri = URI.parse(captcha_image_url)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8"
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["Connection"] = "keep-alive"
      request["Cookie"] = cookie_value
      request["Referer"] = "https://apps.utcourts.gov/CourtsPublicWEB/LoginServlet"
      request["Sec-Fetch-Dest"] = "image"
      request["Sec-Fetch-Mode"] = "no-cors"
      request["Sec-Fetch-Site"] = "same-origin"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
      request["Sec-Ch-Ua"] = "\"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"108\", \"Google Chrome\";v=\"108\""
      request["Sec-Ch-Ua-Mobile"] = "?0"
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      proxy_ip, proxy_port = get_proxy
      response = Net::HTTP.SOCKSProxy(proxy_ip, proxy_port).start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue Exception => e
      puts e
      raise if retries <= 1
      fetch_image(captcha_image_url, cookie_value, retries - 1)
    end
  end

  def fetch_case(url, cookie_value, case_id, court_type, retries = 30)
    begin
      uri = URI.parse(url)
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/x-www-form-urlencoded"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["Cache-Control"] = "max-age=0"
      request["Connection"] = "keep-alive"
      request["Cookie"] = cookie_value
      request["Origin"] = "https://apps.utcourts.gov"
      request["Referer"] = url
      request["Sec-Fetch-Dest"] = "document"
      request["Sec-Fetch-Mode"] = "navigate"
      request["Sec-Fetch-Site"] = "same-origin"
      request["Sec-Fetch-User"] = "?1"
      request["Upgrade-Insecure-Requests"] = "1"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
      request["Sec-Ch-Ua"] = "\"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"108\", \"Google Chrome\";v=\"108\""
      request["Sec-Ch-Ua-Mobile"] = "?0"
      request["Sec-Ch-Ua-Platform"] = "\"Linux\""
      request.set_form_data(
        "caseNumber" => case_id,
        "siteCode" => court_type,
        )
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      proxy_ip, proxy_port = get_proxy
      response = Net::HTTP.SOCKSProxy(proxy_ip, proxy_port).start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue StandardError => e
      puts e
      raise if retries <= 1
      fetch_case(url, cookie_value, case_id, court_type , retries - 1)
    end
  end

  def get_proxy
    proxy_record = PaidProxy.all.to_a.shuffle.first
    proxy_ip = proxy_record['ip']
    proxy_port = proxy_record['port']
    [proxy_ip, proxy_port]
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
