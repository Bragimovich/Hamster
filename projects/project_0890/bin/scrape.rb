# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  manager = Manager.new(options)
  begin
    Hamster.report(to: 'U04JS3K201J', message: "st_0890: Started Scraping!")
    if options[:download]
      manager.download
    elsif options[:store]
      manager.store
    elsif options[:store_prev]
      manager.store_prev_years_data
    elsif options[:store_xls]
      manager.store_xls_files
    else
      manager.scrape
    end
    Hamster.report(to: 'U04JS3K201J', message: "st_0890: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'U04JS3K201J', message: "st_0890:\n#{e.full_message}")
  end
end
