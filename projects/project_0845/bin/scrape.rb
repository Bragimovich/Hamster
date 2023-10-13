# frozen_string_literal: true

require_relative '../lib/manager'
def scrape(options)
  begin
    Hamster.report(to: 'U04JS3K201J', message: "project_0845: Started Scraping!(#{options[:range]})")
    Manager.new.scrape(options)
    Hamster.report(to: 'U04JS3K201J', message: "project_0845: Scraping Done!(#{options[:range]})")
  rescue Exception => e
    Manager.new.clear
    Hamster.report(to: 'U04JS3K201J', message: "project_0845(#{options[:range]}):\n#{e.full_message}")
  end
end