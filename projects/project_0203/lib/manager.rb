require_relative './scraper'
require_relative './parser'
require_relative './keeper'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
  end

  def download
    peon.move_all_to_trash
    logger.info "The Store was cleaned from all files and catalogs".green
    peon.throw_trash(10)
    logger.info "The Trash was cleaned from files and catalogs older than 10 days".green
    scraper = Scraper.new(keeper)
    scraper.scrape
    Hamster.logger.info "Scraped #{scraper.count} news".green
  end

  def store
    files = peon.give_list
    files.each do |file|
      page = peon.give(file: file)
      data = Parser.new(page).parse
      keeper.save_news(data)
    end
    Hamster.logger.info "Parsed #{keeper.count} news".green
  end

  private

  attr_reader :keeper
end
