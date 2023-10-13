# frozen_string_literal: true

require_relative '../lib/parser'

class Scraper < Hamster::Scraper

  DOMAIN = 'https://www.aphis.usda.gov'

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def connect_main(link)
    connect_to("#{DOMAIN}#{link}")
  end

  def connect_link(link)
    connect_to(link)
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      if [301, 302].include? response&.status
        url = response.headers["location"]
        response = connect_to(url)
        return
      end
      retries += 1
    end until response&.status == 200 or retries == 10
    return [response, response&.status]
  end
end
