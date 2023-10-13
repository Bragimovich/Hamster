# frozen_string_literal: true

class Scraper < Hamster::Scraper
  attr_writer :service_arr
  def initialize
    super
    @service = [:azcaptcha_com, :two_captcha_com, :captchas_io, :capsolver_com]
    @service_arr = @service.clone if @service_arr.nil? || @service_arr.empty? 
    @cookie = {}
    @url = "https://isoms.lasallecounty.org/portal/Jail"
    @link = "https://isoms.lasallecounty.org/portal/imahuman"
    proxies = Camouflage.new
    @proxy = proxies.swap
  end

  def link_by
    Hamster.connect_to(url: @url, proxy: @proxy) do |response|
      @raw_cookie = response[:set_cookie]
      set_cookie
      headers = {
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
        "Accept-Encoding" => "gzip, deflate, br",
        "Authority" => "isoms.lasallecounty.org",
        "Referer" => "https://isoms.lasallecounty.org/portal",
        "Cookie" => cookies,
        "Scheme" => "https",
        "Accept-Language" => "ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3",
        "Connection" => "keep-alive",
        "Upgrade-Insecure-Requests" => "1",
        "Sec-Fetch-Dest" => "document",
        "Sec-Fetch-Mode" => "navigate",
        "Sec-Fetch-Site" => "same-origin",
        "Sec-Fetch-User" => "?1" 
        }
      content = Hamster.connect_to(url: response[:location], proxy: @proxy, headers: headers)
      @last_raw_cookie = content.headers[:set_cookie]
      @all_cookie = "#{cookies}; #{@last_raw_cookie.split(';')[0]}"
      return content.body
    end
  end

  def captcha(google_key)
    counts_captcha = 5
    service = @service_arr.sample
    begin
      @logger.debug("captcha start")
      client = Hamster::CaptchaAdapter.new(service, timeout:200, polling:10)
      @logger.debug(service)
      @logger.debug(@service_arr)
      raise "Low Balance" if client.balance < 1
        options = {
          pageurl: @link,
          googlekey: google_key[:key]
        }
      unless (options[:pageurl] && options[:googlekey]).nil?
          decoded_captcha = client.decode_recaptcha_v2(options)
        if decoded_captcha.text.nil?
          @logger.debug("Error: Balance Captcha: " + client.balance)
          @logger.error("Error: Balance Captcha: " + client.balance)
          raise "Decode text Null"
        end
        @capcha_text = decoded_captcha.text
      end
    rescue
      @logger.debug("Error: Balance Captcha: " + client.balance.to_s )
      @logger.error("Error: Balance Captcha: " + client.balance.to_s )
      retry if (counts_captcha -=1) >= 0
      if client.balance < 1
        @service_arr.delete_at(@service_arr.index(service))
        counts_captcha = 5
        service = @service_arr.first
        retry unless @service_arr.empty?
      end
    end
    @logger.debug("Balance Captcha: " + client.balance.to_s)
    @logger.debug("captcha end")
    client.balance.to_f
  end

  def set_cookie
   raw = @raw_cookie.split(";").map do |item|
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
  
  def send_request(google_key, num)
    req_src = {
        "g-recaptcha-response" => @capcha_text ,
        "__RequestVerificationToken" => google_key[:token]
        }
    request = req_src.map {|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join("&")
    header = {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Encoding" => "gzip, deflate, br",
      "Authority" => "isoms.lasallecounty.org",
      "Referer" => "https://isoms.lasallecounty.org/portal/imahuman",
      "Cookie" => @all_cookie,
      "Scheme" => "https",
      "path" => "/portal/imahuman",
      "Origin" => "https://isoms.lasallecounty.org",
      "Accept-Language" => "ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3",
      "Content-Type" => "application/x-www-form-urlencoded",
      "Connection" => "keep-alive",
      "Upgrade-Insecure-Requests" => "1",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1"
      }
    Hamster.connect_to(url: @link, method: :post, proxy: @proxy, req_body: request, headers: header) do |result|
      location = result.headers[:location]
      headers = {
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
        "Accept-Encoding" => "gzip, deflate, br",
        "Authority" => "isoms.lasallecounty.org",
        "Referer" => "https://isoms.lasallecounty.org/portal/imahuman",
        "Cookie" => @all_cookie,
        "Scheme" => "https",
        "path" => location,
        "Origin" => "https://isoms.lasallecounty.org",
        "Accept-Language" => "ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3",
        "Content-Type" => "text/html; charset=utf-8",
        "Upgrade-Insecure-Requests" => "1",
        "Sec-Ch-Ua-Mobile" => "?0",
        "Sec-Fetch-Dest" => "document",
        "Sec-Fetch-Mode" => "navigate",
        "Sec-Fetch-Site" => "same-origin",
        "Sec-Fetch-User" => "?1"
        }
      Hamster.connect_to(url: "https://isoms.lasallecounty.org/portal/Jail?hours=0&pagenum=#{num}", proxy: @proxy, headers: headers) do |web_page|
        return web_page.body
      end
    end
  end
end
