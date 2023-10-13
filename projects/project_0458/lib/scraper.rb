require_relative '../lib/parser'
require_relative '../lib/message_send'
class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
  end

  def links(year)
    url = "https://www.treasurer.ca.gov/news/releases/#{year}/index.asp"
    hamster = Hamster.connect_to(url, proxy_filter: @proxy_filter)
    Parser.new.page_items(hamster, year)
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    puts message
    message_send(message)
  end

  def page(url)
    cobble = Dasher.new(:using=>:cobble)
    pdf = cobble.get(url)
    name = Digest::MD5.hexdigest(url).to_s
    name += '.pdf'
    return if pdf.blank?
    peon.put(file: name, content: pdf)
    puts "PDF File #{name} save!".green
    peon.move_and_unzip_temp(file: name)
    puts "PDF File #{name} move & unzip!".yellow
    Parser.new.pdf(name)
  rescue => e
    if e.message == 'Dictionary key (0) is not a name'
    else
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      puts message
    end
  end
end
