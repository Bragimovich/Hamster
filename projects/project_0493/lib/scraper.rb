require_relative '../lib/parser'

class Scraper <  Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @parser = Parser.new
  end

  def agree_request_token
    response = connect_to("https://iic.ccsheriff.org/")
    token = parser.get_token(response.body)
  end

  def main_page(id, token)
    body = prepare_inner_body(id, token)
    page = connect_to(url:"https://iic.ccsheriff.org/InmateLocator/Details", req_body:body, headers:headers, method: :post)
  end

  def get_token(agree_token)
    response = connect_to("https://iic.ccsheriff.org/InmateLocator",headers: agree_headers ,req_body: agree_post_body(agree_token), method: :post)
    token = parser.get_token(response.body)
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304, 302, 500].include?(response.status)
    end
    response
  end

  private

  attr_reader :parser

  def headers
    {
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
      "Origin" => "https://iic.ccsheriff.org",
      "Referer" => "https://iic.ccsheriff.org/InmateLocator/SearchInmates"
    }
  end

  def agree_headers
    {
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Origin": "https://iic.ccsheriff.org",
      "Referer": "https://iic.ccsheriff.org/",
    }
  end

  def agree_post_body(agree_token)
    "termCheck=on&__RequestVerificationToken=#{agree_token}"
  end

  def prepare_inner_body(booking_number, token)
    "bookingNumber=#{booking_number}&__RequestVerificationToken=#{token}"
  end
end
