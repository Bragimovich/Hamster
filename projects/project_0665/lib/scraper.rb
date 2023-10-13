class Scraper <  Hamster::Scraper
  def fetch_data(counter)
    connect_to("https://data.ct.gov/resource/virr-yb6n.json?$limit=10000&$offset=#{counter}")
  end
end
