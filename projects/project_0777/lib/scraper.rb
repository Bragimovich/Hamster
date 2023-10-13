class Scraper < Hamster::Scraper

  def get_page(url)
     connect_to(url)
  end

end
