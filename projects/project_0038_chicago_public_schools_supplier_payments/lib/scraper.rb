class Scraper < Hamster::Scraper

  def initialize()
    @response
  end

  def load_page(url)
    Hamster.connect_to(url) do |response|
      response.headers[:content_type].match?(%r{text|html|json|stream|xml})
      @response = response
      break if response.status && [200, 304, 302].include?(response.status)
    end
    @response
  end
end
