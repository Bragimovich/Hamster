# frozen_string_literal: true

class Scraper <  Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def connect_page(index)
    Hamster.connect_to("https://www.mackinac.org/salaries?report=any&sort=wage2018-desc&page=#{index}#report")
  end
end
