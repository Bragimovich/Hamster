require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.ice.gov'
    @parser = Parser.new
  end

  def links(page)
    url = "https://www.ice.gov/newsroom?page=#{page}"
    hamster = connect_to(url, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster.status != 200
    @parser.page_items(hamster)
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
    hamster = connect_to(link, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster.status != 200
    hamster
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

  def tags
    url = 'https://www.ice.gov/newsroom?page=0'
    hamster = connect_to(url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster.status != 200
    tags = @parser.tags_parse(hamster)
    tags
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
end