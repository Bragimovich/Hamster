# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_main_page
    connect_to('https://transparent.utah.gov/empdet.php')
  end

  def search_request(letters)
    url = "https://tu-query-handler-prod-uewlhjwsua-wm.a.run.app/"
    connect_to(url: url, req_body: set_form_data(letters), headers: search_headers, method: :post, proxy_filter: @proxy_filter)
  end

  private

  def set_form_data(letters)
    "function=getEmployeeSearch&parameter=%7B%22name%22%3A%22#{letters}%22%7D"
  end

  def search_headers
    {
      "Origin" => "https://transparent.utah.gov",
      "Referer" => "https://transparent.utah.gov/",
      "Sec-Fetch-Dest" => "empty",
      "Sec-Fetch-Mode" => "cors",
      "Sec-Fetch-Site" => "cross-site"
    }
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
    puts '=================================='.yellow
    print 'Response status: '.indent(1, '\t').green
    status = response.status.to_s
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end
end
