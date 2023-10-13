class Scraper < Hamster::Scraper

  def main_page
    connect_to("https://www.fresnosheriff.org/units/records/inmate-search.html", ssl_verify: false)
  end

  def redirect_request(cookie)
    connect_to(url: "https://publicinfo.fresnosheriff.org/InmateInfoV2/search.aspx",headers: redirect_headers(cookie), ssl_verify: false)
  end

  def search(cookie, last_name, first_name, view_state, event_validation, generator, counter, flag)
    connect_to(url: "https://publicinfo.fresnosheriff.org/InmateInfoV2/search.aspx", headers: req_headers(cookie), req_body: form_body(first_name, last_name, view_state, event_validation, generator, counter, flag), method: :post, ssl_verify: false)
  end

  def link_request(link)
    connect_to(url: "https://publicinfo.fresnosheriff.org/InmateInfoV2/#{link}", ssl_verify: false)
  end

  private

  def redirect_headers(cookie)
    getting_common_hearders.merge({
       "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/,*;q=0.8,application/signed-exchange;v=b3;q=0.7",
       "Cookie": cookie,
       "Referer": "https://www.fresnosheriff.org/",
       "Sec-Fetch-Dest": "iframe",
       "Sec-Fetch-Mode": "navigate",
       "Sec-Fetch-Site": "same-site",
       "Upgrade-Insecure-Requests": "1",
    })
  end

  def req_headers(cookie)
    getting_common_hearders.merge({
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "Accept": "*/*",
      "Cache-Control": "no-cache",
      "Cookie": cookie,
      "Origin": "https://publicinfo.fresnosheriff.org",
      "Referer": "https://publicinfo.fresnosheriff.org/InmateInfoV2/search.aspx",
      "Sec-Fetch-Dest": "empty",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Site": "same-origin",
      "X-Microsoftajax": "Delta=true",
    })
  end

  def getting_common_hearders()
    {
      "Authority": "publicinfo.fresnosheriff.org",
    "Accept-Language": "en-US,en;q=0.9",
    "Sec-Ch-Ua": "\"Google Chrome\";v=\"113\", \"Chromium\";v=\"113\", \"Not-A.Brand\";v=\"24\"",
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Ch-Ua-Platform": "\"Linux\"",
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    }
  end

  def form_body(first_name, last_name, view_state, event_validation, generator, counter, flag)
    if flag
      "ScriptManager1=upnlSelections%7CgrvwSelections&tbxBookingNbr=&tbxLastName=#{last_name}*&tbxFirstName=#{first_name}*&__EVENTTARGET=grvwSelections&__EVENTARGUMENT=Page%24#{counter}&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape generator}&__EVENTVALIDATION=#{CGI.escape event_validation}&__ASYNCPOST=true&"
    else
      "ScriptManager1=upnlCriteria%7CbtnSearch&__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape generator}&__EVENTVALIDATION=#{CGI.escape event_validation}&tbxBookingNbr=&tbxLastName=#{last_name}*&tbxFirstName=#{first_name}*&__ASYNCPOST=true&btnSearch=Search"
    end
  end
end
