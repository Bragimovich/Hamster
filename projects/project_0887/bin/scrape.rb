# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  begin
    Hamster.report(to: 'Hatri', message: "project_0887: Started Scraping!")
    manager.store
    Hamster.report(to: 'Hatri', message: "project_0887: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'Hatri', message: "project_0887:\n#{e.full_message}")
  end
end

