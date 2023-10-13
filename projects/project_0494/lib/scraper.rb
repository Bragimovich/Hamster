class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def first_page_response
    url = "https://macsnc.courts.state.mn.us/ctrack/search/publicCaseSearch.do"
    connect_to(url: url, method: :get)
  end

  def get_captcha_page(location_value, cookie_final)
    headers = first_headers(cookie_final)
    url = "https://macsnc.courts.state.mn.us#{location_value}"
    connect_to(url: url, headers: headers)
  end

  def get_submit_page(cookie_final, cookie_value_first)
    updated_headers = first_headers(cookie_final)
    updated_headers["Origin"] = "https://macsnc.courts.state.mn.us"
    updated_headers["Referer"] = "https://macsnc.courts.state.mn.us/ctrack/publicLogin.jsp;#{cookie_value_first}"
    connect_to(url: "https://macsnc.courts.state.mn.us/ctrack/publicLogin.do", headers: updated_headers, req_body: {"submitValue" => "Accept"}.to_a.map { |val| val[0] + "=" + val[1] }.join("&"), method: :post)
  end

  def captcha_req(cookie_final, captcha_response)
    updated_headers = first_headers(cookie_final)
    updated_headers["Origin"] = "https://macsnc.courts.state.mn.us"
    updated_headers["Referer"] = "https://macsnc.courts.state.mn.us/ctrack/publicLogin.do"
    body = {"g-recaptcha-response" => captcha_response}.to_a.map { |val| val[0] + "=" + val[1] }.join("&")
    connect_to(url: "https://macsnc.courts.state.mn.us/ctrack/public/caseCaptcha.do?doContinue", headers: updated_headers, req_body: body, method: :post )
  end

  def get_final_page(cookie_final)
    updated_headers = first_headers(cookie_final)
    updated_headers["Origin"] = "https://macsnc.courts.state.mn.us"
    updated_headers["Referer"] = "https://macsnc.courts.state.mn.us/ctrack/publicLogin.do"
    connect_to(url: 'https://macsnc.courts.state.mn.us/ctrack/search/publicCaseSearch.do', headers: updated_headers)
  end

  def get_search_page(year, month, page, cookie_final)
    body = get_body(year, month, page)
    headers = get_headers(cookie_final)
    url = "https://macsnc.courts.state.mn.us/ctrack/search/publicCaseSearch.do"
    connect_to(url: url, headers:headers, req_body:body, method: :post)
  end

  def pdf_download(url)
    connect_to(url: url){ |resp| resp.headers[:content_disposition].match?(%r{attachment|text|html|json}) }
  end

  def get_inner_page(url, cookie_final)
    headers = get_headers(cookie_final)
    url = "https://macsnc.courts.state.mn.us#{url}"
    connect_to(url: url, headers:headers)
  end

  def get_ajax_calls(values, link, cookie)
    body = get_pdf_req_body(values, link)
    body = body.to_a.map { |val| val[0] + "=" + val[1] }.join("&")
    headers = get_pdf_headers(cookie)
    url = 'https://macsnc.courts.state.mn.us/dwr/call/plaincall/AJAX.getViewDocumentLinks.dwr'
    connect_to(url: url, headers:headers, req_body:body, method: :post)
  end

  private

  def get_pdf_req_body(values, link)
    {
      "callCount" => 1.to_s,
      "page" => "#{link}",
      "httpSessionId" => "",
      "scriptSessionId" => "C8382655AF1B1C645C56D39EC4F25941996",
      "c0-scriptName" => "AJAX",
      "c0-methodName" => "getViewDocumentLinks",
      "c0-id" => "0",
      "c0-param0" => "number:#{values[0].to_i}",
      "c0-param1" => "number:#{values[1].to_i}",
      "c0-param2" => "boolean:false",
      "batchId" => "1",
    }
  end

  def get_pdf_headers(cookie)
    {
      "Accept" => "*/*",
      "Accept-Language" => "en-US,en;q=0.9",
      "Connection" => "keep-alive",
      "Cookie" => cookie,
      "Origin" => "https://macsnc.courts.state.mn.us",
      "Referer" => "https://macsnc.courts.state.mn.us/ctrack/view/publicCaseMaintenance.do?csNameID=80346&csInstanceID=92755",
    }
  end

  def first_headers(cookie_final)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Connection" => "keep-alive",
      "Cookie" => cookie_final,
      "Host" => "macsnc.courts.state.mn.us",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    }
  end

  def get_headers(cookie_final)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Connection" => "keep-alive",
      "Cookie" => cookie_final,
      "Origin" => "https://macsnc.courts.state.mn.us",
      "Referer" => "https://macsnc.courts.state.mn.us/ctrack/search/publicCaseSearch.do",
    }
  end

  def get_body(year, month, page)
    if month<=9
      start_month = "0#{month.to_s}"
      month = month + 1
      end_month = "0#{month.to_s}"
    elsif month == 12
      return "csNumber=&shortTitle=&csGroupID=+&jurisdictionID=+&csStatusVal=+&csTypeID=+&fromDt=12%2F01%2F#{year}&toDt=12%2F31%2F#{year}&csSubTypeID=+&button=Search&action=&startRow=#{(1000*page+1)}&displayRows=1000&orderBy=CsNumber&orderDir=ASC&hrefName=%2Fctrack%2Fcases%2FcaseMaintenance.do%3F&restrictBy=&submitValue=Sort"
    else
      start_month = "#{month.to_s}"
      end_month = month = month + 1
    end
    "csNumber=&shortTitle=&csGroupID=+&jurisdictionID=+&csStatusVal=+&csTypeID=+&fromDt=#{start_month}%2F01%2F#{year}&toDt=#{end_month}%2F01%2F#{year}&csSubTypeID=+&button=Search&action=&startRow=#{(1000*page+1)}&displayRows=1000&orderBy=CsNumber&orderDir=ASC&hrefName=%2Fctrack%2Fcases%2FcaseMaintenance.do%3F&restrictBy=&submitValue=Sort"
  end
end
