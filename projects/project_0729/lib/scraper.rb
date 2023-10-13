# frozen_string_literal: true

class Scraper < Hamster::Scraper
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  DOMAIN = "https://mn.gov/mmb/transparency-mn/payrolldata.jsp"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_xls
    search_headers = headers
    connect_to(url: DOMAIN, headers: search_headers)
  end

  def get_xlsx_file(url)
    connect_to(url)
  end

  def headers
    {
      "authority" => "mn.gov",
      "accept" => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      "accept-language" => 'en-US,en;q=0.9',
      "sec-ch-ua" => '"Chromium";v="112", "Google Chrome";v="112", "Not:A-Brand";v="99"',
      "sec-ch-ua-mobile" => "?0",
      "sec-ch-ua-platform" => '"Linux"',
      "sec-fetch-dest" => "document",
      "sec-fetch-mode" => "navigate",
      "sec-fetch-site" => "none",
      "sec-fetch-user" => "?1",
      "upgrade-insecure-requests" => "1",
      "user-agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36"  
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end
end
