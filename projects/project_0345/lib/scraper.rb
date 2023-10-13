require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
    @host = 'www.state.gov'
  end

  def links(page)
    url = "https://www.state.gov/remarks-and-releases-office-of-international-religious-freedom/page/#{page}/"
    url = 'https://www.state.gov/remarks-and-releases-office-of-international-religious-freedom/' if page == 1
    hamster = Hamster.connect_to(url, headers: { 'Host': @host }, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster&.status != 200
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
    hamster = Hamster.connect_to(link, proxy_filter: @proxy_filter, iteration: 9)
    raise if hamster&.status != 200
    hamster
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
end
