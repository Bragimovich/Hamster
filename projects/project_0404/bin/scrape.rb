# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  Manager.new.scrape

rescue => e
  Hamster.logger.error(e.full_message)
  Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number}: #{e.message}\n#{e.backtrace}", use: :slack)
  exit 1
end
