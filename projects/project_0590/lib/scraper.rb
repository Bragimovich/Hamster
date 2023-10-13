# frozen_string_literal: true

class Scraper < Hamster::Scraper

    def initialize
      super
      @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
      @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
      @headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
        'Cache-Control': 'max-age=0',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36 OPR/94.0.0.0',
      }
    end

    def fetch_main_page
      url = "https://courts.delaware.gov/opinions/index.aspx?ag=supreme+court"
      connect_to(url: url, headers: @headers, method: :get, proxy_filter: @proxy_filter)
    end

    def helper_request(tokens, cookie)
      headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
        'Connection': 'keep-alive',
        'Accept-Encoding': 'gzip, deflate, br',
        'Cache-Control': 'max-age=0',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Host': 'courts.delaware.gov',
        'Origin': 'https://courts.delaware.gov',
        'Referer': 'https://courts.delaware.gov/opinions/index.aspx?ag=supreme+court',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin',
        'Sec-Fetch-User': '?1',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36 OPR/94.0.0.0',
        'Cookies': cookie
      }
      url = "https://courts.delaware.gov/opinions/index.aspx?ag=supreme+court"
      connect_to(url: url, req_body: helper_form(tokens), headers: headers, method: :post, proxy_filter: @proxy_filter)
    end

    def search_request(year, tokens, page_no, cookie)
      headers = {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Cache-Control': 'max-age=0',
        'Connection': 'keep-alive',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Host': 'courts.delaware.gov',
        'Origin': 'https://courts.delaware.gov',
        'Referer': 'https://courts.delaware.gov/opinions/index.aspx?ag=supreme+court',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin',
        'Sec-Fetch-User': '?1',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36 OPR/94.0.0.0',
        'Cookie': cookie
      }
      url = "https://courts.delaware.gov/opinions/index.aspx?ag=supreme+court"
      connect_to(url: url, req_body: set_form_data(year, tokens, page_no), headers: headers, method: :post, proxy_filter: @proxy_filter)
    end

    def download_pdf_from_url(urls)
      cobble = Dasher.new(:using=>:cobble, ssl_verify: false)
      body = cobble.get(urls)
      return body
    end

    private

    def helper_form(tokens)
      form_data = {
        '__VIEWSTATE': tokens[:viewstate],
        '__VIEWSTATEGENERATOR': tokens[:viewstategenerator],
        'ctlOpinions1selagencies': 'Supreme Court',
        'ctlOpinions1selperiods': 'year',
        'ctlOpinions1txtsearchtext': '',
        'ctlOpinions1selresults': '25',
        'ctlOpinions1hdnagency': 'supreme court',
        'ctlOpinions1hdncasetype': '',
        'ctlOpinions1hdndivision': '',
        'ctlOpinions1hdnsortby': '',
        'ctlOpinions1hdnsortorder': '',
        'ctlOpinions1hdnsortbynew': '',
        'ctlOpinions1hdnpageno': '',
      }
      form_data.map {|k,v| "#{k}=#{v}" }.join("&")
    end

    def set_form_data(year, tokens, page_no)
      if page_no == 1
        order = ''
      else
        order = 0
      end
      form_data = {
        '__VIEWSTATE' => tokens[:viewstate],
        '__VIEWSTATEGENERATOR' => tokens[:viewstategenerator],
        'ctlOpinions1selagencies' => 'Supreme Court',
        'ctlOpinions1selperiods' => 'year',
        'ctlOpinions1selyears' => "#{year}",
        'ctlOpinions1txtsearchtext' => '',
        'ctlOpinions1selresults' => '25',
        'ctlOpinions1hdnagency' => 'Supreme Court',
        'ctlOpinions1hdncasetype' => '',
        'ctlOpinions1hdndivision' => '',
        'ctlOpinions1hdnsortby' => '',
        'ctlOpinions1hdnsortorder' => order,
        'ctlOpinions1hdnsortbynew' => '',
        'ctlOpinions1hdnpageno' => page_no
      }
      form_data.map {|k,v| "#{k}=#{v}" }.join("&")
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
      Hamster.logger.debug 'Response status: '.indent(1, '\t').green
      status = response.status.to_s
      Hamster.logger.debug response.status == 200 ? status.greenish : status.red
      Hamster.logger.debug '=================================='.yellow
    end
  end
