require_relative 'scraper'
class Manager < Hamster::Harvester
  #binding.pry
  URL = 'https://www.courts.ri.gov/Courts/SupremeCourt/Pages/Opinions%20and%20Orders%20Issued%20in%20Supreme%20Court%20Cases.aspx'
  def initialize
    super
    #@keeper  = Keeper.new
    #@parser  = Parser.new
    @scraper = Scraper.new(url: URL)
    #@run_id  = @keeper.run_id
  end
  def download
    @scraper.scrape
  end



end