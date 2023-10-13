require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
  end

  def links(page)
    url = "https://oversight.house.gov/release/page/#{page}/"
    url = "https://oversight.house.gov/release/" if page == 1
    hamster = connect_to(url, proxy_filter: @proxy_filter, iteration: 9)
    return if hamster&.status == 404
    raise if hamster&.status != 200
    Parser.new.page_items(hamster)
  rescue => e
    if hamster&.status != 200
      sleep(10)
      retry
    end
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def page(link)
    connect_to(link, proxy_filter: @proxy_filter, iteration: 9)
  end
end

