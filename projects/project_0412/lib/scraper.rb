# frozen_string_literal: true
class Scraper <  Hamster::Scraper

  DOMAIN = "https://www.eeoc.gov"

  def get_page(page_number)
    connect_to(DOMAIN + "/search/advanced-search?search_api_fulltext=&search_api_fulltext_1=&search_api_fulltext_2=&langcode=en&f%5B0%5D=content_type_2_%3Abriefs" + "&page=#{page_number}")
  end
  
  def inner_page(inner_page_url)
    connect_to(inner_page_url)
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
end
