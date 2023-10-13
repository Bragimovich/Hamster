# frozen_string_literal: true

class Scraper < Hamster::Scraper
  SEARCH_URL = 'https://myeclerk.myorangeclerk.com/Cases/Search'
  
  def initialize
    super
    @cookie = {}
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_page(link)
    connect_to(link)
  end

  def search_request(start_date, end_date, letter = '', case_type, capcha_text, captcha_token, cookie)
    connect_to(url: SEARCH_URL, req_body: set_search_form_data(start_date, end_date, letter, case_type, capcha_text, captcha_token), headers: make_headers(cookie), method: :post, proxy_filter: @proxy_filter)
  end

  def inner_page_request(url, cookie)
    connect_to(url: url, headers: make_headers(cookie), method: :get, proxy_filter: @proxy_filter)
  end

  def resolve_captcha(google_key, link)
    captcha_count = 12
    logger.info "captcha starting.."
    begin
      two_captcha = TwoCaptcha.new(Storage.new.two_captcha['general'], timeout:200, polling:10)
        options = {
          pageurl: link,
          googlekey: google_key[:key]
        }
       decoded_captcha = two_captcha.decode_recaptcha_v2(options)
      if decoded_captcha.text.nil?
        logger.error "Error: Balance Captcha: " + two_captcha.balance
        raise "Decode text Null"
      end
      logger.info "captcha soved..! with #{decoded_captcha.text} text.."
      decoded_captcha.text
    rescue
      logger.error "Error: Balance Captcha: #{two_captcha.balance.to_s}"
      retry if (captcha_count -=1) >= 0
    end
  end


  private

  def set_search_form_data(start_date, end_date, letter = '', case_type, capcha_text, captcha_token)
    form_data = {
      "BusinessName" => letter,
      "CaseNumber" => "",
      "CaseTypeGroup" => "all",
      "CitationNumber" => "",
      "DateFrom" => start_date,
      "DateTo" => end_date,
      "CaseTypes"=> case_type,
      "FirstName" => "",
      "LastName" => "",
      "MiddleName" => "",
      "WebRequest" => "",
      "__RequestVerificationToken" => captcha_token,
      "g-recaptcha-response" => capcha_text,
    }
    form_data.to_a.map { |val| val[0] + "=" + val[1] }.join("&")
  end

  def make_headers(cookie)
    set_cookie(cookie)
    {
      "Accept" =>   "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Connection" => "keep-alive",
      "Origin" => "https://myeclerk.myorangeclerk.com",
      "Referer" => "https://myeclerk.myorangeclerk.com/Cases/Search",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Cookie" => cookies
    }
  end

  def set_cookie(raw_cookie)
    raw = raw_cookie.split(";").map do |item|
      item.split(",")
    end.flatten
     
    raw.each do |item|
      if !item.include?("path") && !item.include?("samesite")  && !item.include?("httponly") && !item.empty?
        name, value = item.split("=")
        @cookie.merge!({"#{name}" => value})
      end
    end
   end
 
   def cookies
     @cookie.map {|key, value| "#{key}=#{value}"}.join(";")
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
    logger.info '=================================='
    logger.info 'Response status: '.indent(1, "\t")
    status = response&.status
    if status == 200
      logger.info status 
    else
      logger.error status 
    end
    logger.info '=================================='
  end
end

