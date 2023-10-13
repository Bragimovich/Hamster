# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  manager = Manager.new
  begin
    Hamster.report(to: 'U04JS3K201J', message: "project_0853: Started Scraping!(#{options[:range]})")
    if options[:store]
      manager.store(options)
    else
      manager.scrape(options)
    end
    Hamster.report(to: 'U04JS3K201J', message: "project_0853: Scraping Done!(#{options[:range]})")
  rescue Exception => e
    manager.clear
    Hamster.report(to: 'U04JS3K201J', message: "project_0853(#{options[:range]}):\n#{e.full_message}")
  end
end
