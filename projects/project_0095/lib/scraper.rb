require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.sec.gov'
    @parser = Parser.new
    @url = 'https://www.sec.gov/news/pressreleases'
  end

  def page_items
    hamster = connect_to(@url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    @parser.page_items(hamster)
  end

  def page(link)
    connect_to(link, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
  end
end

