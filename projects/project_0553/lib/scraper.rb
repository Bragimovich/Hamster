# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_main_page
    connect_to('https://sexoffender.dsp.delaware.gov/')
  end

  def search_request(first_letter,last_letter,token,cookie)
    url = "https://sexoffender.dsp.delaware.gov/Search"
    headers = search_headers_updated(cookie)
    connect_to(url: url, req_body: set_form_data(first_letter,last_letter,token), headers: headers, method: :post, proxy_filter: @proxy_filter)
  end

  def check_captcha(cookie, token)
    url = "https://sexoffender.dsp.delaware.gov/CheckCaptcha"
    headers = captcha_headers(cookie)
    data = "__RequestVerificationToken" + token[:token]
    connect_to(url: url, req_body: data, headers: headers, method: :post, proxy_filter: @proxy_filter)
  end

  def search_offender(id,token,cookie)
    url = "https://sexoffender.dsp.delaware.gov/GetOffenderDetails"
    connect_to(url: url, req_body: set_form_data_offender(token,id), headers: search_headers(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  def captcha_verify(captcha_text, token, cookie)
    url = "https://sexoffender.dsp.delaware.gov/VerifyCaptchaJson"
    connect_to(url: url, req_body: set_form_data_captcha(captcha_text, token), headers: search_headers(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  private

  def set_form_data(first_letter,last_letter,token)
    form_data = {
      "ConvictionState" => "*ALL",
      "Development" => "",
      "ExcludeInJail" => "false",
      "FirstName" => first_letter,
      "HouseNumber" => "",
      "IncludeHomeless" => "false",
      "IncludeWanted" => "false",
      "LastName" => last_letter,
      "OnlineId" => "",
      "PageSize" => "8",
      "SearchType" => "offender",
      "StreetName" => "",
      "Workplace" => "",
      "XLongitudeMax" => "",
      "XLongitudeMin" => "",
      "YLatitudeMax" => "",
      "YLatitudeMin" => "",
      "__RequestVerificationToken" => token[:token]
    }
    form_data.map {|k,v| "#{k}=#{v}" }.join("&")
  end

  def set_form_data_captcha(captcha_text, token)
    form_data = {
      "recaptchaResponse" => captcha_text,
      "__RequestVerificationToken" => token[:token]
    }
    form_data.map {|k,v| "#{k}=#{v}" }.join("&")
  end

  def set_form_data_offender(token,id)
    form_data = {
      "__RequestVerificationToken" => token[:token],
      "id" => id
    }
    form_data.map {|k,v| "#{k}=#{v}" }.join("&")
  end

  def search_headers(cookie)
    {
      "Accept" => "application/json, text/javascript, */*; q=0.01",
      "Accept-Encoding" => "gzip, deflate, br",
      "Accept-Language" => "en-GB,en-US;q=0.9,en;q=0.8",
      "Connection" => "keep-alive",
      "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
      "Origin" => "https://sexoffender.dsp.delaware.gov",
      "Host" => "sexoffender.dsp.delaware.gov",
      "Sec-Fetch-Dest" => "empty",
      "Sec-Fetch-Mode" => "cors",
      "Sec-Fetch-Site" => "cross-site",
      "X-Requested-With" => "XMLHttpRequest",
      "user-agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
      "Cookie" => cookie
    }
  end
  def search_headers_updated(cookie)
    {
      'content-type' => 'application/x-www-form-urlencoded; charset=UTF-8',
      'Accept' => 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language' => 'en-GB,en-US;q=0.9,en;q=0.8',
      'Connection' => 'keep-alive',
      'Origin' => 'https://sexoffender.dsp.delaware.gov',
      'Sec-Fetch-Dest' => 'empty',
      'Sec-Fetch-Mode' => 'cors',
      'Sec-Fetch-Site' => 'same-origin',
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36 OPR/95.0.0.0',
      'X-Requested-With' => 'XMLHttpRequest',
      'sec-ch-ua' => '"Opera";v="95", "Chromium";v="109", "Not;A=Brand";v="24"',
      'sec-ch-ua-mobile' => '?0',
      'sec-ch-ua-platform' => '"macOS"',
      'Cookie': cookie
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304, 302, 307].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, '\t').green
    status = response.status.to_s
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end
end
