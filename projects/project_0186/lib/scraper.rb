require_relative '../lib/parser'
require_relative '../lib/message_send'
class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.vhfa.org'
  end

  def links(page)
    links = []
    url = "https://www.vhfa.org/news?page=#{page}"
    hamster = connect_to(url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster.status != 200
    items, items_btn = Parser.new.page_items(hamster)
    unless items.blank?
      items.each do |item|
        url_part = item['href'].to_s
        next unless url_part.include? '/news/blog/'
        page_url = "https://www.vhfa.org#{url_part}"
        logger.info "[#{links.count + 1}] #{page_url}"
        links << page_url
      end
    end
    unless items_btn.blank?
      items_btn.each do |item|
        url_part = item['href'].to_s
        next unless url_part.include? '/news/blog/'
        page_url = "https://www.vhfa.org#{url_part}"
        unless links.include? page_url
          logger.info "[#{links.count + 1}] #{page_url}"
          links.push(page_url)
        end
      end
    end
    links
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
    connect_to(link, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
  end
end
