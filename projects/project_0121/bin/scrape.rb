# frozen_string_literal: true 

require_relative '../lib/manager'

def scrape(options)
 manager = Manager.new
 manager.download(options) if options[:download] || options[:auto] || options[:update]
 manager.store(options) if options[:store] || options[:auto] || options[:update]
rescue StandardError => e
  report to: 'victor lynnyk', message: "121: #{e.full_message}"
  puts ['*'*77, e.backtrace]
  exit 1
end
