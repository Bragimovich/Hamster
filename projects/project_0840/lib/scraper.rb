# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def initialize
    super
    @headers = {
      "Accept-Encoding" => "gzip, deflate, br",
      "Host" => "omsweb.public-safety-cloud.com",
      "Origin" => "https://omsweb.public-safety-cloud.com",
      "Referer" => "https://omsweb.public-safety-cloud.com/jtclientweb/jailtracker/index/Oklahoma_County_OK",
      "content-type" => "application/json; charset=utf-8"
    }
  end

  def main_page
    content = connect_to("https://omsweb.public-safety-cloud.com/jtclientweb/captcha/getnewcaptchaclient")
    json = JSON.parse(content.body)
    @key = json["captchaKey"]
    @img = json["captchaImage"]
    captcha
  end

  def valid_captcha
    request_body = JSON.dump({'captchaKey' => @key, 'captchaImage' => @img, 'userCode' => @capcha_text})
    content = connect_to("https://omsweb.public-safety-cloud.com/jtclientweb/Captcha/validatecaptcha", method: :post, req_body: request_body, headers: @headers )
    JSON.parse(content.body)
  end

  def search_page(captcha_key, char)
    request_body = JSON.dump({'firstName' =>'','lastName' =>"#{char}",'searchType' =>'1','releasedSinceValue'=>'7Days','captchaKey' => captcha_key})
    content = connect_to("https://omsweb.public-safety-cloud.com/jtclientweb/Offender/Oklahoma_County_OK/NameSearch", method: :post, req_body: request_body, headers: @headers )
    JSON.parse(content.body)
  end

  def get_inmate(arrest, view_key, captcha_key)
    request_body = JSON.dump({'captchaKey' => captcha_key, 'captchaImage' => @img, 'userCode' => "null"})
    content = connect_to("https://omsweb.public-safety-cloud.com/jtclientweb/Offender/Oklahoma_County_OK/#{arrest}/offenderbucket/#{view_key}", method: :post, req_body: request_body, headers: @headers )
    json = JSON.parse(content.body)
    @captcha_key = json["captchaKey"]
    json
  end

  def get_image(arrest)
    request_body = JSON.dump({'captchaKey' => @captcha_key, 'captchaImage' => @img, 'userCode' => "null"})
    content = connect_to("https://omsweb.public-safety-cloud.com/jtclientweb/Offender/Oklahoma_County_OK/#{arrest}/image", method: :post, req_body: request_body, headers: @headers )
    JSON.parse(content.body)
  end

  def captcha
    counts_captcha = 5
    begin
      @logger.debug("captcha start")
      @logger.info("captcha start")
      @client = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)
      raise "Low Balance" if @client.balance < 1
      options = { regsense: 1, raw64: @img } 
      unless options[:raw64].nil?
        decoded_captcha = @client.decode_image(options)
        if decoded_captcha.text.nil?
          @logger.debug("Error:Captcha nil")
          raise "Decode text Null"
        end
        @capcha_text = decoded_captcha.text
        @logger.debug("Captcha: #{@capcha_text}")
        @logger.info("Captcha: #{@capcha_text}")
      end
    rescue
      retry if (counts_captcha -=1) >= 0
    end
    @logger.debug("Balance Captcha: " + @client.balance.to_s)
    @logger.info("captcha end")
    @logger.debug("captcha end")
  end
end
