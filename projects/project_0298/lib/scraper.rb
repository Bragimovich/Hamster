class Scraper < Hamster::Scraper
  MAIN_PAGE = 'https://www.sos.ca.gov/elections/voter-registration/voter-registration-statistics'

  def fetch_page(url = MAIN_PAGE)
    Hamster.connect_to(url)
  end
end
