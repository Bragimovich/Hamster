class Scraper < Hamster::Scraper
  MAIN_PAGE = 'https://azsos.gov/elections/voter-registration-historical-election-data/voter-registration-counts'

  def fetch_page(url = MAIN_PAGE)
    Hamster.connect_to(url)
  end
end
