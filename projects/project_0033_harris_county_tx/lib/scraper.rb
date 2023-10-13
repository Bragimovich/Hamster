class Scraper < Hamster::Scraper

  def initialize()
    @response
  end

  def load_page(url)
    Hamster.connect_to(url) do |response|
      response.headers[:content_type].match?(%r{text|html|json|stream})
      reporting_request(response)
      @response = response
      break if response.status && [200, 304, 302].include?(response.status)
    end
    @response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = response&.status
    puts status == 200 ? status.to_s.greenish : status.to_s.red
    puts '=================================='.yellow
  end

end
