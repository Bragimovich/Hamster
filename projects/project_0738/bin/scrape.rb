# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  begin
    Hamster.report(to: 'U04JS3K201J', message: "project_0738: Scraping Started!(#{options[:year]})")
    if options[:store]
      Manager.new.store(options[:year])
    else
      Manager.new.scrape(options[:year])
    end
    Hamster.report(to: 'U04JS3K201J', message: "project_0738: Scraping Done!(#{options[:year]})")
  rescue Exception => e
    Hamster.report(to: 'U04JS3K201J', message: "project_0738(#{options[:year]}):\n#{e.full_message}")
  end
end
