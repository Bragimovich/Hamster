# frozen_string_literal: true

class Scraper < Hamster::Scraper
  MAIN_URL = 'http://www.kansasopengov.org/kog/table_api.php'

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_page(page = '1')
    body = form_data(page)
    body = body.to_a.map { |val| "#{val[0]}=#{val[1]}" }.join('&')
    connect_to(url: MAIN_URL, req_body: body, method: :post, proxy_filter: @proxy_filter)
  end

  private

  def form_data(page)
    {
      'page' => page,
      'report_id' => '4'
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304, 302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = response.status.to_s
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end
end
