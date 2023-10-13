require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
  end
  def download
    if keeper.status == 'finish'
      peon.move_all_to_trash
      logger.info 'The Store was cleaned from all files and catalogs'.green
    end
    peon.throw_trash(30)
    logger.info 'The Trash was cleaned from files and catalogs older than 30 days'.green
    keeper.status = 'scraping'
    scraper = Scraper.new(keeper)
    scraper.scrape
    keeper.status = 'scraped'
    logger.info "##{Hamster.project_number} scraped #{scraper.count} news".green
  end

  def store
    keeper.status = 'parsing'
    files = peon.give_list(subfolder: "#{keeper.run_id}_prices")
    return if files.empty?

    db_date  = keeper.get_last_date
    files.each do |name|
      web_date = name.gsub('.gz', '').split("_")[1].to_date
      next unless web_date > db_date

      page = peon.give(subfolder: "#{keeper.run_id}_prices", file: name)
      data = Parser.new.parse(page, name)
      keeper.save_prices(data[:prices])
      keeper.save_metro_area(data[:metro_areas])
    end
    keeper.finish
    logger.info "##{Hamster.project_number} parsed #{keeper.count} news".green
  end

  private

  attr_reader :keeper
end
