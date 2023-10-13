# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_first_page
    connect_to('https://salarysearch.ibhe.org/search.aspx')
  end

  def get_search_page(vs, vs_generator, event_validator, year)
    connect_to(url: 'https://salarysearch.ibhe.org/search.aspx', req_body: req_body(vs, vs_generator, event_validator, year), method: :post)
  end

  def pagination(vs, vs_generator, event_validator, year, page_num)
    connect_to(url: 'https://salarysearch.ibhe.org/search.aspx', header: headers, req_body: pagination_body(vs, vs_generator, event_validator, year, page_num), method: :post)
  end

  def record(vs, vs_generator, event_validator, year, button_number)
    connect_to(url: "https://salarysearch.ibhe.org/search.aspx", header: headers, req_body: popup(vs, vs_generator, event_validator, year, button_number), method: :post)
  end
  
  private

  def headers
    {
      "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
      "Accept" => "*/*",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "no-cache",
      "Connection" => "keep-alive",
      "Origin" => "https =>//salarysearch.ibhe.org",
      "Referer" => "https =>//salarysearch.ibhe.org/search.aspx",
      "Sec-Fetch-Dest" => "empty",
      "Sec-Fetch-Mode" => "cors",
      "Sec-Fetch-Site" => "same-origin",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
      "X-Microsoftajax" => "Delta=true",
      "X-Requested-With" => "XMLHttpRequest",
      "Sec-Ch-Ua" => '\"Chromium\";v=\"112\", \"Google Chrome\";v=\"112\", \"Not =>A-Brand\";v=\"99\"',
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => '\"Linux\"'
    }
  end

  def pagination_body(vs, vs_generator, event_validator, year, page_num)
    "ctl00%24ScriptManager1=ctl00%24ContentPlaceHolder1%24upnlGridview%7Cctl00%24ContentPlaceHolder1%24gvwSalary&ctl00%24ContentPlaceHolder1%24ddlstYear=#{year}&ctl00%24ContentPlaceHolder1%24lstInstitutions=000000&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByName%24txtLName=&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByName%24txtFName=&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByPos%24lstJobPositions=0&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByTitle%24txtTitle=&__EVENTTARGET=ctl00%24ContentPlaceHolder1%24gvwSalary&__EVENTARGUMENT=Page%24#{page_num}&__VIEWSTATE=#{CGI.escape vs}&__VIEWSTATEGENERATOR=#{CGI.escape vs_generator}&__EVENTVALIDATION=#{CGI.escape event_validator}&ContentPlaceHolder1_tconSearchParam_ClientState=%7B%22ActiveTabIndex%22%3A0%2C%22TabEnabledState%22%3A%5Btrue%2Ctrue%2Ctrue%5D%2C%22TabWasLoadedOnceState%22%3A%5Btrue%2Cfalse%2Cfalse%5D%7D&__VIEWSTATEENCRYPTED=&__ASYNCPOST=true&"
  end

  def popup(vs, vs_generator, event_validator, year, button_number)
    "ctl00%24ScriptManager1=ctl00%24ContentPlaceHolder1%24upnlGridview%7Cctl00%24ContentPlaceHolder1%24gvwSalary&ctl00%24ContentPlaceHolder1%24ddlstYear=#{year}&ctl00%24ContentPlaceHolder1%24lstInstitutions=000000&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByName%24txtLName=&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByName%24txtFName=&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByPos%24lstJobPositions=0&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByTitle%24txtTitle=&__EVENTTARGET=ctl00%24ContentPlaceHolder1%24gvwSalary&__EVENTARGUMENT=Button%24#{button_number}&__VIEWSTATE=#{CGI.escape vs}&__VIEWSTATEGENERATOR=#{CGI.escape vs_generator}&__EVENTVALIDATION=#{CGI.escape event_validator}&ContentPlaceHolder1_tconSearchParam_ClientState=%7B%22ActiveTabIndex%22%3A0%2C%22TabEnabledState%22%3A%5Btrue%2Ctrue%2Ctrue%5D%2C%22TabWasLoadedOnceState%22%3A%5Btrue%2Cfalse%2Cfalse%5D%7D&__VIEWSTATEENCRYPTED=&__ASYNCPOST=true&"
  end

  def req_body(vs, vs_generator, event_validator, year)
    "ctl00%24ScriptManager1=ctl00%24ScriptManager1%7Cctl00%24ContentPlaceHolder1%24btnSearch&ctl00%24ContentPlaceHolder1%24ddlstYear=#{CGI.escape year}&ctl00%24ContentPlaceHolder1%24lstInstitutions=000000&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByName%24txtLName=&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByName%24txtFName=&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByPos%24lstJobPositions=0&ctl00%24ContentPlaceHolder1%24tconSearchParam%24tpnlByTitle%24txtTitle=&__EVENTTARGET=ctl00%24ContentPlaceHolder1%24btnSearch&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape vs}&__VIEWSTATEGENERATOR=#{CGI.escape vs_generator}&__EVENTVALIDATION=#{CGI.escape event_validator}&ContentPlaceHolder1_tconSearchParam_ClientState=%7B%22ActiveTabIndex%22%3A0%2C%22TabEnabledState%22%3A%5Btrue%2Ctrue%2Ctrue%5D%2C%22TabWasLoadedOnceState%22%3A%5Btrue%2Cfalse%2Cfalse%5D%7D&__VIEWSTATEENCRYPTED=&__ASYNCPOST=true&'"
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
