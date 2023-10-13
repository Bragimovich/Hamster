# frozen_string_literal: true

require_relative 'parser'

class Scraper < Hamster::Scraper
  HEADERS = {
      accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      accept_language:           'en-US,en;q=0.5',
      connection:                'keep-alive',
      upgrade_insecure_requests: '1',
      dnt:                       '1'
  }

  def scrape_data
    my_parser = Parser.new

    ('a'..'z').each do |letter|
      response = connect_to(url: "https://cfm10208.com/find-a-member/by-name?search=#{letter}#e",
                            headers: HEADERS,
                            ssl_verify: false)
      my_parser.parse_html(response.body, letter)
    end
  end

  def fetch_phone_number(link, letter)
    req_headers = {
      "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/  signed-exchange;v=b3;q=0.7",
      "Accept-Language"=>"en-GB,en-US;q=0.9,en;q=0.8",
      "Connection"=>"keep-alive",
      "Host"=>"cfm10208.com"
    }
    response = Hamster.connect_to(link,headers: req_headers)
    cookies = response&.headers['set-cookie']
    search_headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Cookie': cookies,
      'Origin': 'https://cfm10208.com',
      'Referer': "https://cfm10208.com/find-a-member/by-name?search=#{letter}"
    }
    headers = req_headers.merge(search_headers)
    response = Hamster.connect_to(link, headers: headers,method: :get)
    response.body
  end
end
