class Scraper < Hamster::Scraper

  def get_file(link)
     connect_to(link)
  end

end
