require_relative '../lib/pa_sc_case_scraper'
require_relative '../lib/pa_sc_case_parser'
require_relative '../lib/pa_sc_case_keeper'

class PaScCaseManager < Hamster::Harvester
  def initialize(**params)
    super
    @keeper = PaScCaseKeeper.new
    @count  = 0
  end

  def download
    peon.move_all_to_trash
    peon.throw_trash(30)
    logger.info 'Trash cleaned'.green
    keeper.status = 'scraping'
    scraper = PaScCaseScraper.new(keeper)
    scraper.scrape_new_cases
    logger.info "Success scrap of new court cases #{scraper.count}".green
    scraper_active = PaScCaseScraper.new(keeper)
    scraper_active.scrape_active_cases if Date.today.day <= 7
    keeper.status = 'scraped'
    logger.info "Success scrap of active court cases #{scraper_active.count}".green
  end

  def store
    keeper.status = 'parsing'
    run_id = keeper.run_id
    pdfs   = peon.give_list(subfolder: "#{run_id}_pdfs")
    pdfs.each do |name|
      pdf_link   = peon.move_and_unzip_temp(file: name, from: "#{run_id}_pdfs")
      parser     = PaScCaseParser.new(pdf: pdf_link)
      case_info  = parser.parse_info
      additional = parser.parse_additional_info
      case_info.merge!({ additional_info: additional })
      keeper.update_info(case_info)
      keeper.save_relations_info_pdf
      keeper.save_additional_info
      party = parser.parse_party
      keeper.save_party(party)
      consolidations = parser.parse_consolidations
      keeper.save_consolidations(consolidations)
      activities = parser.parse_activities
      keeper.save_activities(activities)
      @count += 1
    end
    peon.throw_temps
    logger.info 'Trash cleaned'.green
    keeper.finish
    logger.info "Success parsing: #{@count} files".green
  end

  private

  attr_accessor :keeper
end
