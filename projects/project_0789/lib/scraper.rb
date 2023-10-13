require 'nokogiri'
require 'uri'
require_relative 'parser'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_main_page
    url = "https://jailpublic.westchestergov.com/jailpublic"
    connect_to(url)
  end

  def captcha_verify(captcha_text, token, cookie)
    url = "https://jailpublic.westchestergov.com/jailpublic"
    connect_to(url: url, req_body: set_form_data_captcha(captcha_text, token), headers: search_headers_updated(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  def search_request(first_letter,last_letter,token,cookie,solved_captcha)
    url = "https://jailpublic.westchestergov.com/jailpublic/searchOffender"
    headers = search_headers_updated(cookie)
    connect_to(url: url, req_body: set_form_data(first_letter,last_letter,token,solved_captcha), headers: headers, method: :post, proxy_filter: @proxy_filter)
  end

  def search_booking(id,token,cookie)
    url = "https://jailpublic.westchestergov.com/jailpublic/booking"
    connect_to(url: url, req_body: set_form_data_booking(token,id), headers: search_headers_updated(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  def search_detail(id,booking_id,token,cookie)
    url = "https://jailpublic.westchestergov.com/jailpublic/detail"
    connect_to(url: url, req_body: set_form_data_detail(token,id,booking_id), headers: search_headers_updated(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  private

  def set_form_data_captcha(captcha_text, token)
    form_data = {
      "recaptchaResponse" => captcha_text,
      "CSRFToken" => token[:token]
    }
    form_data.map {|k,v| "#{k}=#{v}" }.join("&")
  end

  def search_headers_updated(cookie)
    {
      'content-type' => 'application/x-www-form-urlencoded; charset=UTF-8',
      'Accept' => 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language' => 'en-GB,en-US;q=0.9,en;q=0.8',
      'Connection' => 'keep-alive',
      'Origin' => 'https://jailpublic.westchestergov.com/jailpublic',
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

  def set_form_data(first_letter,last_letter,token,solved_captcha)
    form_data = {
      'lastName' => last_letter,
      'firstName' => first_letter,
      'nameType' => 'Partial',
      'birthDateDisplay' => '',
      'birthPlace' => '',
      'aliasNameType' => 'Y',
      '_aliasNameType' => 'on',
      'g-recaptcha-response' => solved_captcha,
      'CSRFToken' => token[:token]
    }
    form_data.map {|k,v| "#{k}=#{v}" }.join("&")
  end

  def set_form_data_booking(token,id)
    form_data = {
      "h_rootId" => id,
      "CSRFToken" => token[:token]
    }
    form_data.map {|k,v| "#{k}=#{v}" }.join("&")
  end

  def set_form_data_detail(token,id,booking_id)
    form_data = {
      "h_bookRootID" => id,
      "h_bookingID" => booking_id,
      "CSRFToken" => token[:token]
    }
    form_data.map {|k,v| "#{k}=#{v}" }.join("&")
  end
end
