# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  manager = Manager.new(options)
  begin
    Hamster.report(to: 'XXXXX', message: "st_NNNN: Started Scraping!")
    manager.scrape
    Hamster.report(to: 'XXXXX', message: "st_NNNN: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'XXXXX', message: "st_NNNN:\n#{e.full_message}")
  end
end

