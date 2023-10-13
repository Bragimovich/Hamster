# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    Hamster.report(to: 'Hatri', message: "project_0828: Started Scraping!")
    manager.store
    Hamster.report(to: 'Hatri', message: "project_0828: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'Hatri', message: "project_0828:\n#{e.full_message}")
  end
end
