require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    spreadsheet = @scraper.scrape
    info        = @parser.parse(spreadsheet)
    @keeper.store(info)
    @keeper.finish
    logger.info 'Succes scrape!'.green
  end
end
