require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Harvester

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'homeland.house.gov'
  end

  def links
    links = []
    url = "https://homeland.house.gov/committee-activity/press-releases/"
    hamster = Hamster.connect_to(url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, timeout: 5, iteration: 1)
    raise if hamster.blank? || hamster.status != 200
    links = Parser.new.page_items(hamster)
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    puts message
  ensure
    links
  end

  def page(link)
    Hamster.connect_to(link, proxy_filter: @proxy_filter, iteration: 9)
  end
end
