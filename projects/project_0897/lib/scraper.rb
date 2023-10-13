# frozen_string_literal: true

class Scraper < Hamster::Scraper

  MAIN_HEADERS =  { 
                    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
                    "Accept-Language" => "en-US,en;q=0.9,ur;q=0.8",
                    "Authority" => "ihsa.org",
                    "Cache-Control" => "no-cache",
                    "Pragma" => "no-cache",
                    "Connection" => "keep-alive",
                    "Sec-Fetch-Dest" => "document",
                    "Sec-Fetch-Mode" => "navigate",
                    "Sec-Fetch-Site" => "same-origin",
                    "Sec-Fetch-User" => "?1",
                    "Upgrade-Insecure-Requests" => "1", 
                    "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"                 
                  }
  

  def initialize
    super
    @cookie = {}
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end


  def main_request(url)
    connect_to(url: url, headers: MAIN_HEADERS, method: :get, proxy_filter: @proxy_filter)
  end

  private

  attr_accessor :proxy_filter

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
