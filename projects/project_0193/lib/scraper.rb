require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.foreign.senate.gov'
  end

  def links(source, page)
    links = []
    url = "#{source}?PageNum_rs=#{page}"
    hamster = connect_to(url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster.status != 200
    items = Parser.new.page_items(hamster)
    items.each do |item|
      url = item['href'].to_s.strip
      next if url.include? 'templates/press_release.cfm'
      puts "[#{links.count + 1}] #{url}"
      links << url
    end
    links
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

