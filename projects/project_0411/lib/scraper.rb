# frozen_string_literal: true

class Scraper <  Hamster::Scraper

  DOMAIN    = 'https://ujs.sd.gov'
  SUB_PATH  = '/Supreme_Court/Opinions.aspx'
  URL       = DOMAIN + SUB_PATH

  def initialize
    super  
    @proxy_filter = ProxyFilter.new
  end

  def get_main_page
    connect_to(URL)
  end

  def get_pdfs(url)
    connect_to(DOMAIN + url)
  end

  def get_page(index, __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR, cookie)
    connect_to(url: URL, headers: get_headers(cookie), req_body: prepare_body(index, __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR), method: :post)
  end

  def get_inner_page(index, __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR, cookie)
    connect_to(url: URL, headers: get_headers(cookie), req_body: pagination_body(index, __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR), method: :post)
  end

  private

  def get_headers(cookie)
    {
      "Accept" =>  "*/*",
      "Accept-Language" =>  "en-US,en;q=0.9",
      "Cache-Control" =>  "no-cache",
      "Connection" =>  "keep-alive",
      "Content-Type" =>  "application/x-www-form-urlencoded; charset=UTF-8",
      "Origin" =>  "https://ujs.sd.gov",
      "Cookie" => cookie,
      "Sec-Fetch-Dest" =>  "empty",
      "Sec-Fetch-Mode" =>  "cors",
      "Sec-Fetch-Site" =>  "same-origin",
      "User-Agent" =>  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36",
      "X-MicrosoftAjax" =>  "Delta=true",
      "X-Requested-With" =>  "XMLHttpRequest",
      "sec-ch-ua" =>  "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"100\", \"Google Chrome\";v=\"100\"",
      "sec-ch-ua-mobile" =>  "?0",
      "sec-ch-ua-platform" =>  "\"Linux\"",
    }
  end
  def prepare_body(index, __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR)
    "ctl00%24ctl00%24ScriptManager1=ctl00%24ctl00%24ContentPlaceHolder1%24ChildContent1%24UpdatePanel_Opinions%7Cctl00%24ctl00%24ContentPlaceHolder1%24ChildContent1%24Repeater_OpinionsYear%24ctl0#{CGI.escape index.to_s}%24LinkButton1&__EVENTTARGET=ctl00%24ctl00%24ContentPlaceHolder1%24ChildContent1%24Repeater_OpinionsYear%24ctl0#{CGI.escape index.to_s}%24LinkButton1&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape __VIEWSTATE}&__VIEWSTATEGENERATOR=#{CGI.escape __VIEWSTATEGENERATOR}&__VIEWSTATEENCRYPTED=&__EVENTVALIDATION=#{CGI.escape __EVENTVALIDATION}&__ASYNCPOST=true&"
  end
  def pagination_body(index, __EVENTVALIDATION, __VIEWSTATE, __VIEWSTATEGENERATOR)
    "ctl00%24ctl00%24ScriptManager1=ctl00%24ctl00%24ContentPlaceHolder1%24ChildContent1%24UpdatePanel_Opinions%7Cctl00%24ctl00%24ContentPlaceHolder1%24ChildContent1%24DataList_Paging%24ctl0#{CGI.escape index.to_s}%24LinkButton_Paging&__EVENTTARGET=ctl00%24ctl00%24ContentPlaceHolder1%24ChildContent1%24DataList_Paging%24ctl0#{CGI.escape index.to_s}%24LinkButton_Paging&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape __VIEWSTATE}&__VIEWSTATEGENERATOR=#{CGI.escape __VIEWSTATEGENERATOR}&__VIEWSTATEENCRYPTED=&__EVENTVALIDATION=#{CGI.escape __EVENTVALIDATION}&__ASYNCPOST=true&"
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
