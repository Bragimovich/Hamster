# frozen_string_literal: true

require_relative '../lib/manager'
require_relative '../lib/slack_reporter'

def scrape(options)
  begin
    unless options[:schedules]
      SlackReporter.report(message: "project_0778: Started Scraping!\nOptions: #{options.to_s}")
    end

    manager = Manager.new(options)
    manager.run

    unless options[:schedules]
      SlackReporter.report(message: "project_0778: Scraping Done!\nOptions: #{options.to_s}")
    end
  rescue Exception => e
    unless options[:schedules]
      SlackReporter.report(message: "project_0778:\nOptions: #{options.to_s}\n#{e.full_message}")
    end

    raise e
  end
end
