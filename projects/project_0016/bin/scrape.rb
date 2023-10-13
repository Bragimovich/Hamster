# frozen_string_literal: true

require_relative '../lib/cdc_weekly_counts_of_deaths_by_state_and_select_causes_scraper'

SCRAPE_NAME = '#16 CDC Weekly Counts of Deaths by State and Select Causes'
def scrape(options)
  begin
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Starting scrape...", use: :both)
    cdc = CDCWeeklyCountsOfDeathsByStateAndSelectCausesScraper.new
    status = cdc.download_csv_file
    if status  == 'downloaded'
      cdc.parse_csv_file
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Parsing finished!", use: :both)
    end
    if status  == 'filename_changed'
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Name of file were changed!", use: :both)
    end
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Job finished!!!", use: :both)
  rescue StandardError => e
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: ERROR", use: :both)
    report(to: 'sergii.butrymenko', message: "#{e} | #{e.backtrace}")
  end
end
