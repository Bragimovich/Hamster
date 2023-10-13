# frozen_string_literal: true

class Scraper < Hamster::Scraper
 
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_page(link)
    connect_to(link)
  end

  private

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
    logger.info '=================================='
    logger.info 'Response status: '.indent(1, "\t")
    status = response&.status
    status == 200 ? logger.info status : logger.error status
    logger.info '=================================='
  end
end
