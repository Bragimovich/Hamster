# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def initialize
    super
  end

  def get_json(url)
    max_retries = 19
    retries = 0
    loop do
      response = connect_to(url: url)
      if response.status == 200 || retries == max_retries
        return response
        break
      else
        retries += 1
      end
    end
  end
end
