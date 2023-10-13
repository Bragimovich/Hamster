# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  begin
    Hamster.report(to: 'Hatri', message: "project_0826: Started Scraping!")
    manager.download
    manager.store
    Hamster.report(to: 'Hatri', message: "project_0826: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'Hatri', message: "project_0826:\n#{e.full_message}")
    Hamster.logger.debug(e.full_message)
  end
end

