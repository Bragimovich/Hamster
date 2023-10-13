require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def scrape
    ('a'..'z').each do |letter|
      inmate_ids = @scraper.search_by(letter)
      store(inmate_ids)
      logger.debug("Stored results: last name is #{letter}")
    end
    @keeper.regenerate_and_flush
    @keeper.update_history
    @keeper.finish
  end

  def store(inmate_ids)
    data_source_url = nil
    inamte_data = nil
    inmate_ids.each do |inmate_id|
      response, data_source_url = @scraper.scrape_by(inmate_id)
      inamte_data = @parser.parse_detail_page(response.body, data_source_url, @scraper)
      @keeper.store(inamte_data)
    end
  rescue => e
    logger.info data_source_url
    logger.info inamte_data
    logger.info e.full_message
    raise e
  end

  def clear
    @keeper.regenerate_and_flush
  end
end
