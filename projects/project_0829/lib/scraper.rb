class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_main_page
    url = "http://inmate.kenoshajs.org/NewWorld.InmateInquiry/kenosha?Name=&SubjectNumber=&BookingNumber=&BookingFromDate=&BookingToDate=&Facility="
    connect_to(url: url, proxy_filter: @proxy_filter)
  end

  def current_page_html(url)
    connect_to(url: url, proxy_filter: @proxy_filter)
  end

  def inmate_page(url)
    connect_to(url: url, proxy_filter: @proxy_filter)
  end
end
