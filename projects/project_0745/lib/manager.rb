require_relative 'scraper'
require_relative 'parser'
require_relative 'keeper'

class Manager < Hamster::Harvester
  LINK = 'https://business.nh.gov/inmate_locator/'
  def initialize
    super
    @scraper = Scraper.new
    @parser  = Parser.new
    @keeper  = Keeper.new
  end
  def download
    post_letters = ('a'..'z').to_a
    post_letters.each do |query|
      body       = @scraper.scrape(LINK, query)
      candidates = @parser.parse(body)
      @keeper.store(candidates)
    end
    @keeper.finish
    logger.info 'Succes scrape!'.green
  end
end
