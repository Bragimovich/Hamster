# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def get_source(url)
    connect_to(url: url)&.body
  end
end
