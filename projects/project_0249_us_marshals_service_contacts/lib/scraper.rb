class Scraper < Hamster::Scraper

  def scraper(page)
    url = "https://www.usmarshals.gov/news?page=#{page}"
    connect_to(url:url)&.body
  end

  def download_inner_pages(link)
    connect_to(link)&.body
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
