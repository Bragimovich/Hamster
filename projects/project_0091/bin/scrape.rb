# frozen_string_literal: true 

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new(options)
  manager.download if options[:download] || options[:auto]
  manager.store if options[:store] || options[:auto]
rescue StandardError => e
  pp e.full_message
  report to: 'victor lynnyk', message: "91: #{e}"
  exit 1
end
