# frozen_string_literal: true

require_relative '../lib/manager'
require_relative '../lib/slack_reporter'

def scrape(options)
  begin
    SlackReporter.report(message: "project_0768: Started Scraping!")

    manager = Manager.new
    manager.run

    SlackReporter.report(message: "project_0768: Scraping Done!")
  rescue Exception => e
    SlackReporter.report(message: "project_0768:\n#{e.full_message}")
  end
end
