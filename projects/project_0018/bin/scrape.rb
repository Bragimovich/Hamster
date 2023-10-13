# frozen_string_literal: true

require_relative '../lib/cdc_weekly_counts_of_death_by_jurisdiction_and_cause_of_death_scraper'

SCRAPE_NAME = '#18 CDC Weekly counts of death by jurisdiction and cause of death'
def scrape(options)
  begin
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Starting scrape...", use: :both)
    cdc = CDCWeeklyCountsOfDeathByJurisdictionAndCauseOfDeathScraper.new

    if cdc.download_csv_file == 'downloaded'
      cdc.parse_csv_file
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Parsing finished!", use: :both)
    else
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Can't download file!", use: :both)
    end
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Job finished!!!", use: :both)
  rescue StandardError => e
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: ERROR", use: :both)
    report(to: 'sergii.butrymenko', message: "#{e} | #{e.backtrace}")
  end
end
