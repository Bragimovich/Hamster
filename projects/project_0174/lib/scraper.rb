require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.gsa.gov'
    @url = 'https://www.gsa.gov/about-us/newsroom/news-releases'
  end

  def years
    hamster = Hamster.connect_to(@url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    pages = Parser.new.pages(hamster)
    years = []
    pages.each do |page|
      page = page.text.to_s.gsub(/\D/, '').strip
      years << page
    end
    years
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
    message_send(message)
  end

  def links(year)
    links = []
    url = "https://www.gsa.gov/about-us/newsroom/news-releases?year=#{year}"
    hamster = connect_to(url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    page_items = Parser.new.page_items(hamster)
    page_items.each do |item|
      links << "https://www.gsa.gov#{item['href']}".gsub(' ','%C2%A0').gsub('–','%E2%80%93').gsub('‘','%E2%80%98')
    end
    links
  end

  def page(link)
    connect_to(link, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
  end
end