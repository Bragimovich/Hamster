class Scraper <  Hamster::Scraper

  def main_page(page)
    url = "https://www.mackinac.org/salaries?report=any&sort=name&page=#{page}"
    connect_to(url)
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
end
