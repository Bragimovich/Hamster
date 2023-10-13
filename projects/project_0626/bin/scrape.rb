# frozen_string_literal: true 

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new(options)
  manager.download if options[:download] || options[:auto]
  manager.store if options[:store] || options[:auto]
rescue StandardError => e
  Hamster.logger.error(e.full_message)
  report to: 'D053YNX9V6E', message: "626: #{e.full_message}"
  exit 1
end
