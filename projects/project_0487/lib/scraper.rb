require_relative '../lib/message_send'
require_relative '../lib/parser'

class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
  end

  def links(page)
    url = 'http://inmate.co.kendall.il.us/NewWorld.InmateInquiry/kendall?Name=&SubjectNumber=&BookingNumber=&'
    url += "BookingFromDate=&BookingToDate=&InCustody=&Page=#{page}"
    hamster = Hamster.connect_to(url, proxy_filter: @proxy_filter)
    return if hamster.status != 200
    Parser.new.links(hamster)
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    puts message
    message_send(message)
  end

  def page(link)
    Hamster.connect_to(link, proxy_filter: @proxy_filter)
  end
end
