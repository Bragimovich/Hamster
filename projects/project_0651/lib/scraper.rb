# frozen_string_literal: true
class Scraper < Hamster::Scraper

  def redirect_landing
    connect_to(url: "https://publicrecords.alameda.courts.ca.gov/PRS/Case/SearchByPublicReports")
  end

  def agree_request(cookie)
    connect_to(url: "https://publicrecords.alameda.courts.ca.gov/PRS/Home/Disclaimer", headers: agree_headers(cookie))
  end

  def captcha_request(cookie, captcha)
    header =  agree_headers(cookie).merge({
      "Referer": "https://publicrecords.alameda.courts.ca.gov/PRS/Home/Disclaimer",
    })
    connect_to(url: "https://publicrecords.alameda.courts.ca.gov/PRS/Disclaimer", headers: header, req_body: captcha_body(captcha), method: :post)
  end

  def landing_page(cookie)
    header =  agree_headers(cookie).merge({
      "Referer": "https://publicrecords.alameda.courts.ca.gov/PRS/Home/Disclaimer"
    })
    connect_to(url: "https://publicrecords.alameda.courts.ca.gov/PRS/Case/SearchByPublicReports", headers: header)
  end

  def do_search(cookie, filing_date, case_type, location)
    header =  headers(cookie).merge({
      "Referer": "https://publicrecords.alameda.courts.ca.gov/PRS/Case/SearchByPublicReports",
    })
    connect_to(url: "https://publicrecords.alameda.courts.ca.gov/PRS/Case/SearchByPublicReports", headers: header, req_body: search_body(location, case_type, filing_date), method: :post)
  end

  def json_loading(cookie)
    header =  headers(cookie).merge({
      "Referer": "https://publicrecords.alameda.courts.ca.gov/PRS/Case/SearchByPublicReports"
    })
    connect_to(url: "https://publicrecords.alameda.courts.ca.gov/PRS/Case/LoadCivilCasePublicFilingResult", headers: header, req_body: json_body, method: :post)
  end

  def record_search(cookie, record_id)
    header =  agree_headers(cookie).merge({
      "Referer": "https://publicrecords.alameda.courts.ca.gov/PRS/Case/SearchByPublicReports"
    })
    connect_to(url: "https://publicrecords.alameda.courts.ca.gov/PRS/Case/CaseDetails/#{record_id}", headers: header)
  end

  def record_redirect(cookie, tab_id, record_id)
    header =  headers(cookie).merge({
      "Referer": "https://publicrecords.alameda.courts.ca.gov/PRS/Case/CaseDetails/#{record_id}"
    })
    connect_to(url: "https://publicrecords.alameda.courts.ca.gov/PRS/Case/TabDetails", headers: header, req_body: "tabIndex=#{tab_id}", method: :post)
  end

  def pdf_request(link, cookie)
    headers = {"Cookie" => cookie}
    connect_to(url: link, headers: headers)
  end

  private

  def captcha_body(captcha)
    "g-recaptcha-response=#{captcha.text}&CaptchaText=#{captcha.text}"
  end

  def search_body(location, case_type, filing_date)
    "SelectedCourtLocation=#{location}&SelectedCaseSubTypeId=#{case_type}&FilingDate=#{filing_date}"
  end

  def json_body
    "_search=false&nd=#{(Time.now.to_f*1000).to_i}&rows=15&page=1&sidx=&sord=asc"
  end

  def headers(cookie)
    {
      "Content-Type": "application/x-www-form-urlencoded",
      "Cookie": cookie,
      "Origin": "https://publicrecords.alameda.courts.ca.gov",
    }
  end

  def agree_headers(cookie)
    {
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Cookie": cookie,
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

end
