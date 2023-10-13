# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def get_main_response
    url = 'http://kanview.ks.gov/DataDownload.aspx'
    connect_to(url: url,method: :get)
  end

  def get_post_response(cookie_value,event_val,view_state,view_state_gen,year)
    url = 'http://kanview.ks.gov/DataDownload.aspx'
    headers = {}
    headers['Cookie'] = cookie_value
    body = prepare_body(event_val,view_state,view_state_gen,year)
    connect_to(url: url,method: :post,headers: headers,req_body: body,proxy_filter: @proxy_filter)
  end

  private

  def prepare_body(event_val,view_state,view_state_gen,year)
    "__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=#{CGI.escape view_state}&__VIEWSTATEGENERATOR=#{CGI.escape view_state_gen}&__SCROLLPOSITIONX=0&__SCROLLPOSITIONY=1218&__EVENTVALIDATION=#{CGI.escape event_val}&ctl00%24MainContent%24uxAgencyList=&ctl00%24MainContent%24uxTypeList=&ctl00%24MainContent%24uxYearList=&ctl00%24MainContent%24uxVendorYearList=&ctl00%24MainContent%24uxQtrList=&ctl00%24MainContent%24uxMonthList=&ctl00%24MainContent%24uxEmpYearList=#{CGI.escape year}&ctl00%24MainContent%24uxEmpDownloadBtn=Download+Employee+Compensation+Data"
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    Hamster.logger.info 'Response status: '.indent(1, "\t").green
    status = response&.status
    Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
  end

end
