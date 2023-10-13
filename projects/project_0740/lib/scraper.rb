# frozen_string_literal: true

class Scraper < Hamster::Scraper

    def initialize
      super
      @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
      @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
      @headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept-Language': 'en-GB,en;q=0.9',
        'Cache-Control': 'max-age=0',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 OPR/97.0.0.0'
      }
    end

    def fetch_main_page
      url = "https://casesearch.cookcountyclerkofcourt.org/CivilCaseSearchAPI.aspx"
      connect_to(url: url, headers: @headers, method: :get, proxy_filter: @proxy_filter)
    end

    def fetch_case(tokens, case_number)
      url = "https://casesearch.cookcountyclerkofcourt.org/CivilCaseSearchAPI.aspx"
      connect_to(url: url, req_body: set_form_data(tokens, case_number), headers: @headers, method: :post, proxy_filter: @proxy_filter)
    end

    private


    def set_form_data(tokens, case_number)
      form_data = "__EVENTTARGET=&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=#{CGI.escape tokens[:viewstate]}&__VIEWSTATEGENERATOR=#{CGI.escape tokens[:viewstategenerator]}&__VIEWSTATEENCRYPTED=&__EVENTVALIDATION=#{CGI.escape tokens[:eventvalidation]}&ctl00%24MainContent%24ddlDatabase=#{tokens[:type]}&ctl00%24MainContent%24rblSearchType=CaseNumber&ctl00%24MainContent%24txtCaseNumber=#{CGI.escape case_number}&ctl00%24MainContent%24btnSearch=Start%2BNew%2BSearch"
      return form_data
    end

    def connect_to(*arguments, &block)
      response = nil
      10.times do
        response = super(*arguments, &block)
        reporting_request(response)
        break if response&.status && [200, 304, 302, 307].include?(response.status)
      end
      response
    end

    def reporting_request(response)
      Hamster.logger.debug '=================================='.yellow
      status = response&.status.to_s
      Hamster.logger.debug 'Response status: '.green + (status == "200" ? status.greenish : status.red)
      Hamster.logger.debug '=================================='.yellow
    end
  end
