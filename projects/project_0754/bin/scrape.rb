# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    Hamster.report(to: 'U047MQ36JH5', message: "project_0754: Started Scraping!")
    Manager.new(**options)
    Hamster.report(to: 'U047MQ36JH5', message: "project_0754: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'U047MQ36JH5', message: "project_0754:\n#{e.full_message}")
  end
end