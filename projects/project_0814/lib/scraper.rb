class Scraper < Hamster::Scraper
  def initialize
    super
    @cobble = Dasher.new(using: :cobble)
  end

  def main_page
     connect_to("https://sheriff.utahcounty.gov/api/search/active")
  end

  def inner_page(id)
      connect_to("https://sheriff.utahcounty.gov/api/search/inmate/#{id}")
  end
end
