# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_outer_page(url, first_name, last_name)
    url = "#{url}api/public/profiles?firstName.contains=#{first_name}&lastName.contains=#{last_name}&memberTypeId.equals=0&page=0&size=50"
    Hamster.connect_to(url)
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      if ([301, 302].include? response&.status) ||  (response.body.nil?)
        url = response.headers["location"]
        response = connect_to(url)
        return
      end
      retries += 1
    end until (retries == 10) || ((response&.status == 200 && response.headers['content-type'] == 'application/json'))
    response
  end
end
