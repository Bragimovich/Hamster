# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  begin
    Hamster.report(to: 'U04JS3K201J', message: "project_721: Started scraping")
    Manager.new.scrape
    Hamster.report(to: 'U04JS3K201J', message: "project_721: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'U04JS3K201J', message: "project_721:\n#{e.full_message}")
  end
end
