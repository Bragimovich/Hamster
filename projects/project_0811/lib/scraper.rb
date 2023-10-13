# frozen_string_literal: true

class Scraper < Hamster::Scraper

    def initialize
      super
      @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
      @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
      @headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
        'Cache-Control': 'max-age=0',
        'Connection': 'keep-alive',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Origin': 'http://www.ctinmateinfo.state.ct.us',
        'Referer': 'http://www.ctinmateinfo.state.ct.us/',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 OPR/98.0.0.0'
      }
      @headers2 = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
        'Cache-Control': 'max-age=0',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 OPR/98.0.0.0',
      }
    end

    def get_inmate_detail(link)
      connect_to(url: link, headers: @headers2, method: :get, proxy_filter: @proxy_filter)
    end

    def get_search_inmates()
      url = "http://www.ctinmateinfo.state.ct.us/resultsupv.asp"
      connect_to(url: url, req_body: set_form_data(), headers: @headers, method: :post, proxy_filter: @proxy_filter)
    end

    private


    def set_form_data()
      form_data = "id_inmt_num=&nm_inmt_last=%25&nm_inmt_first=&dt_inmt_birth=&submit1=Search+All+Inmates"
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
