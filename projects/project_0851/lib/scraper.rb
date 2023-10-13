# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_page(url)
    connect_to(url: url)
  end

  def fetch_searched_page(last_name, cookie_value)
    connect_to(url: "http://www.ctinmateinfo.state.ct.us/resultsupv.asp", req_body: get_search_request_body(last_name), headers: get_search_page_headers(cookie_value), method: :post, proxy_filter: @proxy_filter)
  end

  def fetch_inner_page(url, cookie_value)
    connect_to(url: url, req_body: "", headers: get_inner_page_headers(cookie_value), proxy_filter: @proxy_filter)
  end

  private

  def get_search_request_body(last_name)
    "dt_inmt_birth=&id_inmt_num=&nm_inmt_first=&nm_inmt_last=#{last_name}&submit1=Search%All%Inmates"
  end

  def get_search_page_headers(cookie_value)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Cache-Control" => "max-age=0",
      "Connection" => "keep-alive",
      "Cookie" => cookie_value,
      "Origin" => "http://www.ctinmateinfo.state.ct.us",
      "Referer" => "http://www.ctinmateinfo.state.ct.us/",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    }
  end

  def get_inner_page_headers(cookie_value)
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Connection" => "keep-alive",
      "Cookie" => cookie_value,
      "Referer" => "http://www.ctinmateinfo.state.ct.us/resultsupv.asp",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200,304,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    Hamster.logger.info 'Response status: '.indent(1, "\t").green
    status = response&.status
    Hamster.logger.info status == 200 ? status.to_s.greenish : status.to_s.red
  end

end
