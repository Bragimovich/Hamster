require_relative '../lib/pa_philadelphia_court_scraper'
require_relative '../lib/pa_philadelphia_court_parser'
require_relative '../lib/pa_philadelphia_court_keeper'

class PaPhiladelphiaCourtManager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = PaPhiladelphiaCourtKeeper.new
  end

  def download
    if keeper.status == 'finish'
      peon.move_all_to_trash
      logger.info 'The Store was cleaned from all files and catalogs'.green
    end
    peon.throw_trash(30)
    logger.info 'The Trash was cleaned from files and catalogs older than 30 days'.green
    keeper.status = 'scraping'
    scraper = PaPhiladelphiaCourtScraper.new(keeper)
    scraper.scrape_new_cases
    logger.info "Success new court scraping #{scraper.count}".green
    scraper_active = PaPhiladelphiaCourtScraper.new(keeper)
    scraper_active.scrape_active_cases if Date.today.day >= 8 && Date.today.day <= 14
    logger.info "Success active court scraping #{scraper_active.count}".green
    keeper.status = 'scraped'
  end

  def store
    keeper.status = 'parsing'
    run_id     = keeper.run_id
    names_pdfs = peon.give_list(subfolder: "#{run_id}_docket_sheet")
    names_pdfs.each do |name|
      file      = peon.move_and_unzip_temp(file: name, from: "#{run_id}_docket_sheet")
      parser    = PaPhiladelphiaCourtParser.new(pdf: file)
      case_info = parser.parse_info
      next unless case_info

      keeper.update_case_info(case_info)
      next unless keeper.save_case_relations_info_pdf

      case_party = parser.parse_case_party
      keeper.save_case_party(case_party)
      activities = parser.parse_activities
      keeper.save_activities(activities)
    end
    peon.throw_temps
    logger.info 'The Trash was cleaned from no compressed files'.green
    keeper.finish
    logger.info "Success parsing: #{keeper.count} files".green
  end

  private

  attr_accessor :keeper
end
