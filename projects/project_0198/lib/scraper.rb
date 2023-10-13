require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.hsgac.senate.gov'
  end

  def links(source, page)
    url = "#{source}?jsf=jet-engine:press-list&pagenum=#{page}"
    hamster = connect_to(url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster.status != 200
    Parser.new.page_items(hamster)
  rescue => e
    if hamster.status != 200
      retry
    else
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
  end

  def page(link)
    hamster = connect_to(link, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster.status != 200
    hamster
  rescue => e
    if hamster.status != 200
      retry
    else
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      message_send(message)
    end
  end
end

