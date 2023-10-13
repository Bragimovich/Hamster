# frozen_string_literal: true

class FootballScraper < Hamster::Scraper

  def initialize
    super
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @uri_proxy = Camouflage.new
  end

  def page_content(url_file)
    attempts ||= 1
    connect_to(url_file, proxy_filter: @filter, ssl_verify: false)&.body
  rescue StandardError => error
    puts error
    if (attempts += 1) <= 3
      puts "<Attempt #{attempts}: retrying ...>"
      retry
    end
    puts "-------------------------"
    puts "Retry attempts exceeded. Moving on."
    return nil
  end

  def open_content(url)
    attempts ||= 1
    user_agent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36'
    URI.open(url, 'User-Agent' => user_agent, :proxy => @uri_proxy.swap).read
  rescue StandardError => e
    puts e
    if (attempts += 1) <= 3
      puts "<Attempt #{attempts}: retrying ...>"
      retry
    end
    puts "-------------------------"
    puts "Retry attempts exceeded. Moving on."
    return nil
  end
end
