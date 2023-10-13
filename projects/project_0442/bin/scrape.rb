# frozen_string_literal: true 

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new(options)
  manager.download_business if options[:download] || options[:auto] || options[:update]
  manager.download_person if options[:download] || options[:auto] || options[:update]
  manager.check_balance(options) #if options[:download] || options[:auto] || options[:update] || options[:store] || options[:store_and_update]
  manager.download_case(options) if options[:download_case] || options[:auto] || options[:update]
  #manager.store(options) if options[:store] || options[:store_and_update]
rescue StandardError => e
  Hamster.logger.error(e.full_message)
  report to: 'D053YNX9V6E', message: "442: #{e}"
  exit
end
