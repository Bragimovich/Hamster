class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200,304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_main_page
    Hamster.connect_to(url: "https://arc-sos.state.al.us/CGI/corpnumber.mbr/input")
  end

  def profession_page_html()
    Hamster.connect_to(url: "https://arc-sos.state.al.us/CGI/corpnumber.mbr/input")
  end

  def scrape_inner_page(link)
    Hamster.connect_to(url:link)
  end
end
