# frozen_string_literal: true

require_relative '../lib/us_dept_fcc_categories_scraper'
require_relative '../lib/us_dept_fcc_scrape'
require_relative '../lib/us_dept_fcc_parser'

def scrape(options)
  begin
    if options[:sync_categories]
      scraper_category = UsDeptFccCategoriesScraper.new
      scraper_category.scraper
    elsif options[:download]
      scraper_us_dept_fcc = UsDeptFccScrape.new
      scraper_us_dept_fcc.scraper
    elsif options[:parser]
      parser_us_dept_fcc = UsDeptFccParser.new
      parser_us_dept_fcc.parser
    end
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'UK50M4K3R', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
