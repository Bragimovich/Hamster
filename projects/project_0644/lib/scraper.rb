
class Scraper < Hamster::Scraper

  def authentication_connect(captcha_text)
    connect_to(url: "https://nimbus.kern.courts.ca.gov/authenticate-portal", headers: authentication_headers, req_body: authentication_body(captcha_text), method: :post)
  end

  def main_page(start_date, end_date, cookie_value)
    url = "https://nimbus.kern.courts.ca.gov/case-search/filed-date?startDate=#{start_date}&endDate=#{end_date}&caseType=Civil"
    headers = get_headers(cookie_value)
    connect_to(url, headers: headers)
  end

  def inner_pages(url)
    headers = {}
    headers["Orign"] = "https://portal.kern.courts.ca.gov"
    headers["Referer"] = "https://portal.kern.courts.ca.gov/"
    info = connect_to("#{url}/header", headers: headers)
    parties = connect_to("#{url}/parties", headers: headers)
    events = connect_to("#{url}/events", headers: headers)
    [info, parties, events]
  end

  def activity_pdf_request(url, cookie_value)
    headers = get_headers(cookie_value)
    connect_to(url, headers: headers)
  end

  private

  def get_headers(cookie_value)
    headers = {}
    headers["Cookie"] = cookie_value
    headers["Orign"] = "https://portal.kern.courts.ca.gov"
    headers["Referer"] = "https://portal.kern.courts.ca.gov/"
    headers
  end

  def authentication_body(captcha_text)
    {"recaptcha":"#{captcha_text}"}.to_json
  end

  def authentication_headers
    {
      "Content-Type": "application/json",
      "Accept": "application/json, text/plain, */*",
      "Accept-Language": "en-US,en;q=0.9",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      "Cookie": "KCSC_EXTERNAL=",
      "Origin": "https://portal.kern.courts.ca.gov",
      "Referer": "https://portal.kern.courts.ca.gov/",
      "Sec-Fetch-Dest": "empty",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Site": "same-site",
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36",
      "Sec-Ch-Ua": "\"Not_A Brand\";v=\"99\", \"Google Chrome\";v=\"109\", \"Chromium\";v=\"109\"",
      "Sec-Ch-Ua-Mobile": "?0",
      "Sec-Ch-Ua-Platform": "\"Linux\"",
    }
  end
end
