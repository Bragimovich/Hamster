# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  begin
    Hamster.report(to: 'U04JS3K201J', message: "project_0586: Started Scraping!")
    Manager.new.scrape
    Hamster.report(to: 'U04JS3K201J', message: "project_0586: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'U04JS3K201J', message: "project_0586:\n#{e.full_message}")
  end
end
