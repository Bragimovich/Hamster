# frozen_string_literal: true

class Scraper <  Hamster::Scraper
  
  MAIN_URL = "https://portal.ncbar.gov/verification/search.aspx"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def fetch_main_page
    Hamster.connect_to(MAIN_URL)
  end

  def search_main_page(body_info, profession)
    body = prepare_body(profession, body_info[0], body_info[1], body_info[2], body_info[3])
    connect_to(url:MAIN_URL, req_body:body, method: :post, proxy_filter: @proxy_filter)  
  end

  def profession_page_html(cookie_value)
    headers = {}
    headers["Cookie"] = cookie_value
    url = "https://portal.ncbar.gov/Verification/results.aspx"
    Hamster.connect_to(url: url, headers:headers)
  end

  def scrape_inner_page(inner_link, cookie_value)
    lawyers_info_headers = {}
    lawyers_info_headers["Cookie"] = cookie_value
    Hamster.connect_to(url:inner_link, headers:lawyers_info_headers)
  end

  private

  def prepare_body(search_text, view_state_generation, view_state, event_validation, button)
    "__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape view_state_generation}&__EVENTVALIDATION=#{CGI.escape event_validation}&ctl00%24Content%24txtFirst=&ctl00%24Content%24txtMiddle=&ctl00%24Content%24txtLast=#{CGI.escape search_text}&ctl00%24Content%24txtCity=&ctl00%24Content%24ddState=&ctl00%24Content%24ddJudicialDistrict=&ctl00%24Content%24txtLicNum=&ctl00%24Content%24ddLicStatus=&ctl00%24Content%24ddLicType=&ctl00%24Content%24ddSpecialization=&ctl00%24Content%24btnSubmit=#{CGI.escape button}"
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
