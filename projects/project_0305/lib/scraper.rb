class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def main_page
    url = 'https://cookcountypublichealth.org/epidemiology-data-reports/communicable-disease-data-reports/'
    Hamster.connect_to(url, proxy_filter: @proxy_filter)
  end

  def pdf_reader(data)
    io = open(data)
    reader = PDF::Reader.new(io)
    page = reader.pages[0]
    page.text.scan(/^.+/)
  end
end

