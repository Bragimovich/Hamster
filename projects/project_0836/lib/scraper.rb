# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def get_main_page
    url = 'https://www3.pbso.org/blotter/index.cfm'
    connect_to(url: url, method: :get, proxy_filter: @proxy_filter)
  end

  def get_result_page(cookie, last_name, xisi_value, start_date, end_date)
    url = 'https://www3.pbso.org/blotter/searchresults.cfm'
    body = get_result_page_body(last_name, xisi_value, start_date, end_date)
    connect_to(url: url, method: :post, headers: get_result_page_headers(cookie), req_body: body, proxy_filter: @proxy_filter)
  end

  def get_pagination_page(cookie, fr_value, xisi_value)
    url = "https://www3.pbso.org/blotter/searchresults.cfm?fr=#{fr_value}&f=1&xisi=#{xisi_value}"
    connect_to(url: url, method: :get, headers: get_pagination_headers(cookie), proxy_filter: @proxy_filter)
  end

  private

  def get_result_page_headers(cookie)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Connection" => "keep-alive",
      "Cookie" => cookie,
      "Origin" => "https://www3.pbso.org",
      "Referer" => "https://www3.pbso.org/blotter/index.cfm",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\""
    }
  end

  def get_pagination_headers(cookie)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Connection" => "keep-alive",
      "Cookie" => cookie,
      "Referer" => "https://www3.pbso.org/blotter/searchresults.cfm",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "same-origin",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
      "Sec-Ch-Ua" => "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\""
    }
  end

  def get_result_page_body(last_name, xisi_value, start_date, end_date)
    "dave=&fa=searchresults1&fr=1&f=1&xisi=#{CGI.escape xisi_value}&start_date=#{CGI.escape start_date}&end_date=#{CGI .escape end_date}&lastName=#{last_name}&firstName=&Address1=&City=&Statute=&arrestingAgency=&process=Process+Search"
  end

  def connect_to(*arguments, &block)
    response = nil
    20.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200,304].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    Hamster.logger.info 'Response status: '.indent(1, "\t").green
    status = response&.status
    Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
  end

end
