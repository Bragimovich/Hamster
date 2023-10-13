class Scraper < Hamster::Scraper

  def fetch_main_page
     connect_to('http://www.transparency.ri.gov/payroll/')
  end

  def get_year_page(cookie, year)
     url = "http://www.transparency.ri.gov/payroll/verify_prep.php"
     body = "last=&earningType=0&regotEarnings=0&fYear=#{year}&Submited=True&submit=Search"
     connect_to(url: url, req_body: body, headers: get_headers(cookie), method: :post)
  end

  def get_csv(cookie)
    url = "http://www.transparency.ri.gov/payroll/sendtocsv.php?"
    connect_to(url: url, headers: headers_for_csv(cookie))
  end

  def get_headers(cookie)
      {
        "Content-Type" => "application/x-www-form-urlencoded",
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "Cookie" => cookie,
        "Origin" => "http://www.transparency.ri.gov",
        "Proxy-Connection" => "keep-alive",
        "Referer" => "http://www.transparency.ri.gov/payroll/",
      }
  end

  def headers_for_csv(cookie)
      {
        "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "Cookie" => cookie,
        "Proxy-Connection" => "keep-alive",
        "Referer" => "http://www.transparency.ri.gov/payroll/verify_prep.php",
      }
  end

end
