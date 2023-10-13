# frozen_string_literal: true 

require_relative '../lib/manager'

def scrape(options)
 manager = Manager.new
 manager.download if options[:download] || options[:auto]
 manager.store if options[:store] || options[:auto]
rescue StandardError => e
  report to: 'victor lynnyk', message: "386: #{e.full_message}"
  exit 1
end
