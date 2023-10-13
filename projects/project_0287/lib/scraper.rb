require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.justice.gov'
  end

  def links
    url = 'https://www.justice.gov/ocdetf/press-room'
    hamster = Hamster.connect_to(url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster.status != 200
    Parser.new.page_items(hamster)
  rescue => e
    if hamster.status != 200
      sleep 10
      retry
    else
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
      message_send(message)
    end
  end

  def page(link)
    Hamster.connect_to(link, proxy_filter: @proxy_filter, iteration: 9)
  end
end