require_relative '../../../lib/scraper'

class Scraper < Hamster::Scraper

  def initialize
    super
    @cobble = Dasher.new(using: :cobble, redirect: true)
  end

  def main_page(query)
    url = 'https://www.exim.gov/news'
    @cobble.get(url + query)
  end

  def article_page(url)
    10.times do
      response = Hamster.connect_to(url)
      return response.body if [200,301,304,308,307].include?(response&.status)  end
    end

end


