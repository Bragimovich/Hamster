class Scraper <  Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def landing_request
    connect_to(url: "https://floir.com/tools-and-data/catastrophe-reporting", proxy_filter: @proxy_filter)
  end

  def getting_request(url)
    connect_to(url: url, proxy_filter: @proxy_filter)
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    25.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304, 302].include?(response.status)
    end
    response 
  end

end
