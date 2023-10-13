# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def get_main_page(url)
    connect_to(url: url,method: :get,headers: get_headers,proxy_filter: @proxy_filter)
  end

  def get_inner_page(url)
    connect_to(url: url,method: :get,headers: get_headers,proxy_filter: @proxy_filter)
  end

  private

  def get_headers
    {
      "Authority" => "apps.elections.virginia.gov",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Sec-Ch-Ua" => "\"Chromium\";v=\"106\", \"Google Chrome\";v=\"106\", \"Not;A=Brand\";v=\"99\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\"",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "none",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36"
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    20.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200,304,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    Hamster.logger.debug '=================================='.yellow
    Hamster.logger.info 'Response status: '.indent(1, "\t").green
    status = response&.status
    Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
    Hamster.logger.debug '=================================='.yellow
  end

end
