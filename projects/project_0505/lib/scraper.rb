require_relative '../lib/message_send'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Scraper < Hamster::Scraper

  def page(url, headers)
    connect_to(url, headers: headers)
  end

  def page_post(url, headers, req_body)
    connect_to(url, headers: headers, method: :post, req_body: req_body)
  end

  def page_login(url)
    connect_to(url)
  end
end
