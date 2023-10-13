class Scraper < Hamster::Scraper
  def initialize(**option)
    super
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @url = option[:url]
  end

  def scrape
    binding.pry
    #response = connect_to(@url, proxy_filter: @proxy_filter, ssl_verify: false)
    response = URI.open(@url) #.read .open
    site     = Nokogiri::HTML(response)
    binding.pry
  end
end
