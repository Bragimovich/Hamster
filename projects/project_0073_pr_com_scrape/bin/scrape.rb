# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  begin
    Hamster.report(to: 'Bhawna Pahadiya', message: "project_0073: Started Scraping!")
    if options[:download].present?
      manager.download
    else
      manager.store
    end
    Hamster.report(to: 'Bhawna Pahadiya', message: "project_0073: Scraping Done!")
  rescue Exception => e
    manager.clear
    logger.debug e.full_message
    Hamster.report(to: 'Bhawna Pahadiya', message: "project_0073:\n#{e.full_message}")
  end
end
