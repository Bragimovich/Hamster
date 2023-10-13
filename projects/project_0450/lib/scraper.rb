class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_main_page
    url = "https://epay.18thjudicial.org/Clerk/search.do"
    connect_to(url:url)
  end

  def get_inner_page(token, cookie, case_number)
    cookie = cookie.split.first[0..-2]
    url = "https://epay.18thjudicial.org/Clerk/caseNumberSearch.do"
    body = "org.apache.struts.taglib.html.TOKEN=#{token}&caseNumber=#{case_number}"
    headers = get_search_headers(cookie)
    connect_to(url:url, headers: headers, req_body: body, method: :post, proxy_filter: @proxy_filter)
  end

  def get_results_page(token, letter, cookie)
    cookie = cookie.split.first[0..-2]
    url = "https://epay.18thjudicial.org/Clerk/caseNameSearch.do\;#{cookie.gsub('JSESSIONID','jsessionid')}"
    body = get_body(token, letter)
    headers = get_search_headers(cookie)
    connect_to(url:url, headers: headers, req_body: body, method: :post, proxy_filter: @proxy_filter)
  end

  def get_next_activity(cookie, body)
    cookie = cookie.split.first[0..-2]
    url = "https://epay.18thjudicial.org/Clerk/caseNumberSearch.do"
    headers = get_search_headers(cookie)
    connect_to(url:url, headers: headers, req_body: body, method: :post, proxy_filter: @proxy_filter)
  end

  def get_next_page(token, letter, cookie, page, next_page, total)
    cookie = cookie.split.first[0..-2]
    url = "https://epay.18thjudicial.org/Clerk/caseNameSearch.do"
    body = pagination_body(token, letter, page, next_page, total)
    headers = get_search_headers(cookie)
    connect_to(url:url, headers: headers, req_body: body, method: :post, proxy_filter: @proxy_filter)
  end

  def get_cases_page(cookie, token, javascript_parameters)
    javascript_parameters = javascript_parameters.map{ |a| a.gsub("'","").strip}
    cookie = cookie.split.first[0..-2]
    url = "https://epay.18thjudicial.org/Clerk/caseAgainstDefendantSearch.do\;#{cookie.gsub('JSESSIONID','jsessionid')}"
    body = get_case_page_body(token, javascript_parameters)
    headers = get_search_headers(cookie)
    connect_to(url:url, headers: headers, req_body: body, method: :post, proxy_filter: @proxy_filter)
  end

  private

  def get_search_headers(cookie)
    {
      "Authority" =>"epay.18thjudicial.org",
      "Accept" =>"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Accept-Language" =>"en-US,en;q=0.9",
      "Cache-Control" =>"max-age=0",
      "Cookie" => cookie,
      "Origin" =>"https://epay.18thjudicial.org",
      "Referer" =>"https://epay.18thjudicial.org/Clerk/caseNameSearch.do",
    }
  end

  def get_case_page_body(token, javascript_parameters)
    "org.apache.struts.taglib.html.TOKEN=#{token}&birthDate=#{javascript_parameters[0]}&partyNameID=#{javascript_parameters[1]}&firstName=#{javascript_parameters[2]}&lastName=#{javascript_parameters[3].gsub(" ","+")}&middleName=#{javascript_parameters[4]}&birthDateStrip=#{javascript_parameters[5]}"
  end

  def pagination_body(token, letter, page, next_page, total)
    "org.apache.struts.taglib.html.TOKEN=#{token}&birthDate=&firstName=&lastName=#{letter}&middleName=&searchType=Organization&pageNo=#{next_page}&pageSize=10&startRecord=0&totalRecords=#{total}&sel_pageno_1=#{page}&sel_pageno_2=#{page+1}"
  end
  def get_body(token, letter)
    "org.apache.struts.taglib.html.TOKEN=#{token}&lastName=#{letter}&searchType=Organization"
  end
end
