require_relative '../lib/us_dhs_fema_scraper'
require_relative '../lib/us_dhs_fema_parser'
require_relative '../lib/us_dhs_fema_keeper'
class UsDhsFemaManager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = UsDhsFemaKeeper.new
  end

  def download
    scraper = UsDhsFemaScraper.new(keeper.run_id)
    scraper.start
    Hamster.logger.info "##{Hamster.project_number} scraped #{scraper.count} news"
  end

  def store
    run_id     = keeper.run_id
    pages_name = peon.give_list(subfolder: "#{run_id}_pages")
    pages_name.each do |page|
      page_html = peon.give(file: page, subfolder: "#{run_id}_pages")
      parser    = UsDhsFemaParser.new(page_html)
      data      = parser.parse_page
      data[:run_id] = run_id
      keeper.save_to_db(data)
    end
    keeper.finish
    Hamster.logger.info "##{Hamster.project_number} parsed #{keeper.count} news"
  end

  private

  attr_accessor :keeper
end
