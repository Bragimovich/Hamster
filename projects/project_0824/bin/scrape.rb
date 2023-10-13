# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  begin
    Hamster.report(to: 'Bhawna Pahadiya', message: "project_0824: Started Scraping!")
    if options[:download].present?
      manager.download
    else
      manager.store
    end
    Hamster.report(to: 'Bhawna Pahadiya', message: "project_0824: Scraping Done!")
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'Bhawna Pahadiya', message: "project_0824:\n#{e.full_message}")
  end
end
