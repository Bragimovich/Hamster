# frozen_string_literal: true

class Scraper <  Hamster::Scraper

 URL = "https://records.hawaiicounty.gov/weblink/browse.aspx?dbid=1&cr=1"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def outer_page_request
    connect_to(URL, proxy_filter: @proxy_filter)
  end

  def outer_page_request_two(cookie)
    headers = ({
      "Cookie" => "#{cookie};  AcceptsCookies=1",
      "Referer" => "https://records.hawaiicounty.gov/WebLink/Welcome.aspx?cr=1",
     })
    connect_to(URL,  headers: headers, proxy_filter: @proxy_filter)
  end

  def get_main_page(cookie, second_cookie)
    headers = ({
      "Cookie" => "#{cookie};  AcceptsCookies=1; #{second_cookie}",
     })
    connect_to(URL,  headers: headers, proxy_filter: @proxy_filter)
  end

  def get_inner_folder(form_data_info, cookie)
    body = prepare_body(form_data_info, "1")
    headers = ({
      "Cookie" => cookie,
      "Referer" => "https://records.hawaiicounty.gov/weblink/browse.aspx?dbid=1&cr=1",
     })
    connect_to(URL,  headers: headers, req_body:body, method: :post, proxy_filter: @proxy_filter)
  end

  def get_pdf(id)
     url = "https://records.hawaiicounty.gov/weblink/1/edoc/#{id}/FIRE%20CHIEFS%20REPORT%20FY20-21%20APRIL.pdf"
     connect_to(url)
  end

  private

  def prepare_body (form_data, search_folderID)
    "__EVENTTARGET=#{CGI.escape form_data[0]}&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape form_data[2]}&__VIEWSTATEGENERATOR=#{CGI.escape form_data[3]}&__PREVIOUSPAGE=#{CGI.escape form_data[4]}&__EVENTVALIDATION=#{CGI.escape form_data[1]}&searchBox=&searchLoc=0&searchFolderID=#{search_folderID}&TheDocumentBrowser%3AXScrollPosition=0&TheDocumentBrowser%3AYScrollPosition=0"
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
