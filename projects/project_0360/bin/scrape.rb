# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  manager = Manager.new
  begin
    Hamster.report(to: 'U04JS3K201J', message: "project_0360: Started Scraping!(#{options})")
    if options[:pdf]
      manager.scrape_pdfs(options)
    else
      manager.scrape(options)
    end
    Hamster.report(to: 'U04JS3K201J', message: "project_0360: Scraping Done!(#{options})")
  rescue Exception => e
    Hamster.report(to: 'U04JS3K201J', message: "project_0360(#{options}):\n#{e.full_message}")
  end
end
