# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def get_main_request
    connect_to("https://mcle.wcc.ne.gov/ext/SearchLawyer.do")
  end

  def get_search_request(cookie_value)
    connect_to(url: "https://mcle.wcc.ne.gov/ext/SearchLawyer.do;#{cookie_value.downcase}", headers: get_headers(cookie_value), req_body: search_body, method: :post)
  end

  def get_pagination_request(cookie_value, page_number)
    connect_to(url: "https://mcle.wcc.ne.gov/ext/SearchLawyer.do", headers: get_headers(cookie_value), req_body: paginated_body(page_number), method: :post)
  end

  def get_inner_request(id, cookie_value)
    connect_to(url: "https://mcle.wcc.ne.gov/ext/ViewLawyer.do?id=#{id}", headers: record_headers(cookie_value))
  end

  private

  def search_body
    "directPageNumber=&action=search&lastName=&firstName=&countyOfBusiness="
  end

  def paginated_body(page_number)
    "directPageNumber=#{page_number}&action=goToPage&orderBy=&sortBy=&lastName=&firstName=&countyOfBusiness="
  end

  def get_headers(cookie_value)
    {
      "Content-Type": "application/x-www-form-urlencoded",
      "Authority": "mcle.wcc.ne.gov",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language": "en-US,en;q=0.9",
      "Cache-Control": "max-age=0",
      "Cookie": cookie_value,
      "Origin": "https://mcle.wcc.ne.gov",
      "Referer": "https://mcle.wcc.ne.gov/ext/SearchLawyer.do",
      "Sec-Ch-Ua": "\"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"108\", \"Google Chrome\";v=\"108\"",
      "Sec-Ch-Ua-Mobile": "?0",
      "Sec-Ch-Ua-Platform": "\"Linux\"",
      "Sec-Fetch-Dest": "document",
      "Sec-Fetch-Mode": "navigate",
      "Sec-Fetch-Site": "same-origin",
      "Sec-Fetch-User": "?1",
      "Upgrade-Insecure-Requests": "1",
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
    }
  end

  def record_headers(cookie_value)
    {
      "Authority": "mcle.wcc.ne.gov",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language": "en-US,en;q=0.9",
      "Cookie": cookie_value,
      "Referer": "https://mcle.wcc.ne.gov/ext/SearchLawyer.do",
      "Sec-Ch-Ua": "\"Not?A_Brand\";v=\"8\", \"Chromium\";v=\"108\", \"Google Chrome\";v=\"108\"",
      "Sec-Ch-Ua-Mobile": "?0",
      "Sec-Ch-Ua-Platform": "\"Linux\"",
      "Sec-Fetch-Dest": "document",
      "Sec-Fetch-Mode": "navigate",
      "Sec-Fetch-Site": "same-origin",
      "Sec-Fetch-User": "?1",
      "Upgrade-Insecure-Requests": "1",
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36",
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
