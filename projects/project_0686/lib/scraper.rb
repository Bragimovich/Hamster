# frozen_string_literal => true
class Scraper < Hamster::Scraper

  def fetch_csv(url)
    connect_to(url)
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304, 302, 307].include?(response.status)
    end
    response
  end

end
