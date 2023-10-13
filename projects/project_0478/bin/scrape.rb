# frozen_string_literal: true 

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  manager.download if options[:download] || options[:auto]
  manager.store if options[:store]
rescue StandardError => e
  Hamster.logger.error(e.full_message)
  report to: 'D053YNX9V6E', message: "478: #{e.full_message}"
  exit 1
end
