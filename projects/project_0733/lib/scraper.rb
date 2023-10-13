# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def get_main_response
    url = 'https://www.seethroughny.net/payrolls'
    connect_to(url: url,method: :get)
  end

  def get_post_response(cookie_value,year,page_no)
    url = 'https://www.seethroughny.net/tools/required/reports/payroll?action=get'
    body = prepare_body(year,page_no)
    connect_to(url: url,method: :post,headers: get_headers(cookie_value),req_body: body,proxy_filter: @proxy_filter,timeout: 60)
  end

  private

  def prepare_body(year,page_no)
    "PayYear%5B%5D=#{year}&SortBy=YTDPay+DESC&current_page=#{page_no}&result_id=0&url=%2Ftools%2Frequired%2Freports%2Fpayroll%3Faction%3Dget&nav_request=0"
  end

  def get_headers(cookie)
    {
      "Authority" => "www.seethroughny.net",
      "Accept" => "application/json, text/javascript, */*; q=0.01",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cookie" => cookie,
      "Origin" => "https://www.seethroughny.net",
      "Referer" => "https://www.seethroughny.net/payrolls",
      "Sec-Ch-Ua" => "\"Chromium\";v=\"106\", \"Google Chrome\";v=\"106\", \"Not;A=Brand\";v=\"99\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\"",
      "Sec-Fetch-Dest" => "empty",
      "Sec-Fetch-Mode" => "cors",
      "Sec-Fetch-Site" => "same-origin",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36",
      "X-Requested-With" => "XMLHttpRequest"
    }
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
    Hamster.logger.info 'Response status: '.indent(1, "\t").green
    status = response&.status
    Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
  end

end
