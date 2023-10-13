# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  manager = Manager.new(options)
  begin
    report(to: 'U04JS3K201J', message: "st_0743: Started Scraping!")
    if options[:download]
      manager.download(options)
    elsif options[:store]
      manager.store(options)
    else
      manager.scrape(options)
    end
    report(to: 'U04JS3K201J', message: "st_0743: Scraping Done!")
  rescue Exception => e
    report(to: 'U04JS3K201J', message: "st_0743:\n#{e.full_message}")
  end
end

