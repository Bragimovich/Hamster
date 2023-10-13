# frozen_string_literal: true

class Scraper < Hamster::Scraper
  DOMAIN = "https://www.cclerk.hctx.net"
  MAIN_URL = "https://www.cclerk.hctx.net/applications/websearch/CourtSearch.aspx?CaseType=Civil"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def main_page(url = "")
    response = url.empty? ? connect_to(MAIN_URL) : connect_to(DOMAIN + url)
  end

  def year_page(year, body, cookie, url = "", inner_url = "", party = "")
    body = url.empty? ? prepare_body(body, year) : prepare_inner_body(body, year, inner_url, party)
    url = url.empty? ? (MAIN_URL) : (DOMAIN + url)
    connect_to(url: url, headers: get_headers(cookie, url), req_body: body, method: :post)
  end

  private

  def prepare_inner_body(body, year, inner_url, party)
    date = end_date(year)
    "__LASTFOCUS=&__EVENTTARGET=#{CGI.escape inner_url}&__EVENTARGUMENT=#{CGI.escape party}&__VIEWSTATE=#{CGI.escape body[0]}&__VIEWSTATEGENERATOR=#{CGI.escape body[2]}&__VIEWSTATEENCRYPTED=&__EVENTVALIDATION=#{CGI.escape body[1]}&ctl00%24ContentPlaceHolder1%24hfViewImage=0&ctl00%24ContentPlaceHolder1%24hfViewCopyOrders=False&ctl00%24ContentPlaceHolder1%24hfViewDocDesc=False&ctl00%24ContentPlaceHolder1%24hfViewECart=False&ctl00%24ContentPlaceHolder1%24txtCaseNo=&ctl00%24ContentPlaceHolder1%24ddlCourt=All&ctl00%24ContentPlaceHolder1%24DropDownListStatus=-All&ctl00%24ContentPlaceHolder1%24txtDateFrom=1%2F1%2F#{year}&ctl00%24ContentPlaceHolder1%24txtDateTo=#{date}&ctl00%24ContentPlaceHolder1%24rblPartyType=Party&ctl00%24ContentPlaceHolder1%24txtLastName=&ctl00%24ContentPlaceHolder1%24txtFirstName=&ctl00%24ContentPlaceHolder1%24txtMiddleName=&ctl00%24ContentPlaceHolder1%24txtBarNo=&ctl00%24ContentPlaceHolder1%24txtDateFrom2=&ctl00%24ContentPlaceHolder1%24txtDateTo2="
  end

  def prepare_body(body, year)
    date = end_date(year)
   "__EVENTTARGET=&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{CGI.escape body[0]}&__VIEWSTATEGENERATOR=#{CGI.escape body[2]}&__VIEWSTATEENCRYPTED=&__EVENTVALIDATION=#{CGI.escape body[1]}&ctl00%24ContentPlaceHolder1%24txtFileNo=&ctl00%24ContentPlaceHolder1%24ddlCourt=All&ctl00%24ContentPlaceHolder1%24DropDownListStatus=-All&ctl00%24ContentPlaceHolder1%24txtFrom=01%2F01%2F#{year}&ctl00%24ContentPlaceHolder1%24txtTo=#{date}&ctl00%24ContentPlaceHolder1%24btnSearchCase=Search&ctl00%24ContentPlaceHolder1%24rblPartyType=Party&ctl00%24ContentPlaceHolder1%24txtLastName=&ctl00%24ContentPlaceHolder1%24txtFirstName=&ctl00%24ContentPlaceHolder1%24txtMiddleName=&ctl00%24ContentPlaceHolder1%24txtBarNo=&ctl00%24ContentPlaceHolder1%24txtFrom2=&ctl00%24ContentPlaceHolder1%24txtTo2="
  end

  def end_date(year)
    date = (year == Date.today.year) ?  Date.today.to_s.split("-").rotate.join("/") : "12/31/#{year}"
    CGI.escape date
  end

  def get_headers(cookie, url)
    {
     "Authority" => "ia-plb.my.site.com",
     "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
     "Accept-Language" => "en-US,en;q=0.9",
     "Cache-Control" => "max-age=0",
     "Cookie" => cookie,
     "Origin" => "https://www.cclerk.hctx.net",
     "Referer" => url,
     "Sec-Ch-Ua" => "\"Google Chrome\";v=\"107\", \"Chromium\";v=\"107\", \"Not=A?Brand\";v=\"24\"",
     "Sec-Ch-Ua-Mobile" => "?0",
     "Sec-Ch-Ua-Platform" => "\"Linux\"",
     "Sec-Fetch-Dest" => "document",
     "Sec-Fetch-Mode" => "navigate",
     "Sec-Fetch-Site" => "same-origin",
     "Sec-Fetch-User" => "?1",
     "Upgrade-Insecure-Requests" => "1",
     "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36",
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
