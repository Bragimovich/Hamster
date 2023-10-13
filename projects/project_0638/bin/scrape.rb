# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:auto]
    manager.start
  else
    manager.start
  end
rescue => e
  Hamster.logger.error(e.full_message)
  Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number}: #{e.message}\n#{e.backtrace}")
  exit 1
end
