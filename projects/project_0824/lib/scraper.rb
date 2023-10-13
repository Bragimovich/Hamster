
require_relative 'parser'
require 'net/http'
require 'uri'

class Scraper < Hamster::Scraper

  BASE_URL = 'https://www.nd.gov/docr/offenderlkup/'
  
  HEADERS = {
    accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    accept_language:           'en-US,en;q=0.5',
    connection:                'keep-alive',
    upgrade_insecure_requests: '1',
    dnt:                       '1'
  }

  def scrape_data
    parser = Parser.new

    ('a'..'z').each do |letter|
      url = "https://www.nd.gov/docr/offenderlkup/nameprocessor.asp"
      payload = {'lastName': "#{letter}%"}
      response = fetch_data_from_site(url, payload)
      parser.parse_html(response, letter)
    end
  end

  def fetch_data_from_site(url, payload)
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url.path)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    payload = payload
    request.body = URI.encode_www_form(payload)
    response = http.request(request)
    response.body
  end
end
