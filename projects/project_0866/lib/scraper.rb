# frozen_string_literal: true

class Scraper < Hamster::Scraper

    def initialize
      super
      @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
      @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
      @headers = {
        'authority': 'www.nh.gov',
        'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
        'cache-control': 'max-age=0',
        'sec-ch-ua': '"Chromium";v="112", "Not_A Brand";v="24", "Opera";v="98"',
        'upgrade-insecure-requests': '1',
        'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36 OPR/98.0.0.0',
      }
    end

    def fetch_main_page
      url = "https://www.nh.gov/transparentnh/search/index.htm"
      connect_to(url: url, headers: @headers, method: :get, proxy_filter: @proxy_filter)
    end

    def download_file(link)
      url = link
      connect_to(url: url, headers: @headers, method: :get, proxy_filter: @proxy_filter)
    end

    private
    attr_accessor :latters

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
