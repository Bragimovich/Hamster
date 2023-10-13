# frozen_string_literal: true

require_relative '../lib/cdc_excess_deaths_scraper'
SCRAPE_NAME = '#6 CDC Excess Deaths'
def scrape(options)
  begin
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Starting scrape...", use: :both)
    cdc = CDCExcessDeathsScraper.new
    if cdc.download_csv_file == 'downloaded'
      cdc.parse_csv_file
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Parsing finished!", use: :both)
      # cdc.move_csv_file
      report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: CSV file moved to trash!", use: :both)
    end
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: Job finished!!!", use: :both)
  rescue StandardError => e
    report(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME}: ERROR", use: :both)
    report(to: 'sergii.butrymenko', message: "#{e} | #{e.backtrace}")
  end
end
