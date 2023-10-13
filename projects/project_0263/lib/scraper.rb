require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
  end

  def links(page)
    url = "https://www.rd.usda.gov/newsroom/news-releases?page=#{page}"
    hamster = connect_to(url, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster.status != 200
    Parser.new.page_items(hamster)
  rescue => e
    if hamster.status != 200
      sleep 10
      retry
    else
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
  end

  def page(link)
    connect_to(link, proxy_filter: @proxy_filter, iteration: 9)
  end
end
