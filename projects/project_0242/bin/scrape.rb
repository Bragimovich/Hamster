# frozen_string_literal: true

require_relative '../lib/manager'
require_relative '../lib/slack_reporter'

def scrape(options)
  begin
    SlackReporter.report(message: "Started Scraping!\nOptions: #{options.to_s}")

    manager = Manager.new(options)
    manager.run

    SlackReporter.report(message: "Scraping Done!\nOptions: #{options.to_s}")
  rescue Exception => e
    SlackReporter.report(message: "Options: #{options.to_s}\n#{e.full_message}") unless e.is_a?(Interrupt)
  end
end
