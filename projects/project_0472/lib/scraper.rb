class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def scraper
    url = "https://www.montanabar.org/cv5/cgi-bin/memberdll.dll/List?RANGE=1/10000&CUSTOMERTYPE=%3C%3EAPPLICANT&CUSTOMERTYPE=%3C%3ELAY_LAWSTU&CUSTOMERTYPE=%3C%3ELAY_MEMBER&CUSTOMERTYPE=%3C%3ELAY_SECT&PETNAMES=%3C%3EY"
    connect_to(url:url)&.body
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
end
