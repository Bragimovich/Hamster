class Scraper <  Hamster::Scraper
  def connect_to(url)
    response = nil
    10.times do
      response = Hamster.connect_to(url)
      break if response&.status && [200].include?(response.status)
    end
    response
  end
end
