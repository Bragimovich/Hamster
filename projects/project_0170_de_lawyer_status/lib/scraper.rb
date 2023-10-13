# frozen_string_literal: true

class Scraper <  Hamster::Scraper

  MAIN_PAGE = "https://rp470541.doelegal.com/vwPublicSearch/Show-VwPublicSearch-Table.aspx"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def fetch_outer_page
    connect_to(url: MAIN_PAGE, headers:headers, proxy_filter:@proxy_filter)
  end

  def fetch_first_page(cookie, get_body_data, letter)
    form_data       = generate_form(get_body_data[0] ,get_body_data[1], letter, 1)
    updated_headers = get_headers(cookie)
    connect_to(url:MAIN_PAGE, headers: updated_headers, req_body: form_data, method: :post, proxy_filter:@proxy_filter)
  end

  def fetch_next_page(view_generator, next_viewstate, letter, next_page, cookie)
    updated_headers = get_headers(cookie)
    next_form_data  = pagination_form(view_generator, next_viewstate, letter, next_page)
    connect_to(url:MAIN_PAGE, headers: updated_headers, req_body: next_form_data, method: :post, proxy_filter:@proxy_filter)
  end

  private

  def get_headers(cookie)
    new_headers = headers
    new_headers.merge({
      "Cookie" => cookie,
    })
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

  def generate_form(view_generator , viewstate, input,page_number)
    "ctl00%24scriptManager1=ctl00%24PageContent%24UpdatePanel1%7Cctl00%24PageContent%24SearchButton&ctl00_scriptManager1_HiddenField=%3B%3BAjaxControlToolkit%2C%20Version%3D4.1.60919.0%2C%20Culture%3Dneutral%2C%20PublicKeyToken%3D28f01b0e84b6d53e%3Aen-US%3Aee051b62-9cd6-49a5-87bb-93c07bc43d63%3A5546a2b%3A475a4ef5%3Ad2e10b12%3Aeffe2a26%3A37e2e5c9%3A5a682656%3A12bbc599%3B&isd_geo_location=%3Clocation%3E%0A%3Clatitude%3E37.40%3C%2Flatitude%3E%0A%3Clongitude%3E-121.93%3C%2Flongitude%3E%0A%3Cunit%3Emeters%3C%2Funit%3E%0A%3Cerror%3ELOCATION_ERROR_DISABLED%3C%2Ferror%3E%0A%3C%2Flocation%3E%0A&ctl00%24pageLeftCoordinate=&ctl00%24pageTopCoordinate=&ctl00%24PageContent%24SearchText=#{input}&ctl00%24PageContent%24Pagination%24_CurrentPage=#{page_number}&ctl00%24PageContent%24Pagination%24_PageSizeSelector=250&ctl00%24PageContent%24VwPublicSearchTableControl_PostbackTracker=&hiddenInputToUpdateATBuffer_CommonToolkitScripts=1&__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape viewstate}&__VIEWSTATEGENERATOR=#{CGI.escape view_generator}&__ASYNCPOST=true&ctl00%24PageContent%24SearchButton.x=1&ctl00%24PageContent%24SearchButton.y=-1"
  end

  def pagination_form(view_generator , next_viewstate, input,page_number)
    "ctl00%24scriptManager1=ctl00%24PageContent%24UpdatePanel1%7Cctl00%24PageContent%24Pagination%24_NextPage&ctl00_scriptManager1_HiddenField=%3B%3BAjaxControlToolkit%2C%20Version%3D4.1.60919.0%2C%20Culture%3Dneutral%2C%20PublicKeyToken%3D28f01b0e84b6d53e%3Aen-US%3Aee051b62-9cd6-49a5-87bb-93c07bc43d63%3A5546a2b%3A475a4ef5%3Ad2e10b12%3Aeffe2a26%3A37e2e5c9%3A5a682656%3A12bbc599%3B&isd_geo_location=%3Clocation%3E%0A%3Clatitude%3E37.40%3C%2Flatitude%3E%0A%3Clongitude%3E-121.93%3C%2Flongitude%3E%0A%3Cunit%3Emeters%3C%2Funit%3E%0A%3Cerror%3ELOCATION_ERROR_DISABLED%3C%2Ferror%3E%0A%3C%2Flocation%3E%0A&ctl00%24pageLeftCoordinate=&ctl00%24pageTopCoordinate=&ctl00%24PageContent%24SearchText=#{input}&ctl00%24PageContent%24Pagination%24_CurrentPage=#{page_number}&ctl00%24PageContent%24Pagination%24_PageSizeSelector=250&ctl00%24PageContent%24VwPublicSearchTableControl_PostbackTracker=&hiddenInputToUpdateATBuffer_CommonToolkitScripts=1&__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape next_viewstate}&__VIEWSTATEGENERATOR=#{CGI.escape view_generator}&__ASYNCPOST=true&ctl00%24PageContent%24Pagination%24_NextPage.x=12&ctl00%24PageContent%24Pagination%24_NextPage.y=12"
  end

  def headers
    {
      "Origin"  => "https://rp470541.doelegal.com",
      "Referer" => "https://rp470541.doelegal.com/vwPublicSearch/Show-VwPublicSearch-Table.aspx",
    }
  end

end
