# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  manager.clear_files
  begin
    Hamster.report(to: 'U04JS3K201J', message: "project_0585: Started Scraping(#{options[:type]})!")
    if options[:weekly].present?
      manager.weekly_scrape
    else
      manager.scrape(options[:type])
    end
    Hamster.report(to: 'U04JS3K201J', message: "project_0585: Scraping Done!(#{options[:type]})")
  rescue Exception => e
    manager.clear
    logger.debug e.full_message
    Hamster.report(to: 'U04JS3K201J', message: "project_0585:\n#{e.full_message}")
  end
end
