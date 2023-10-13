# frozen_string_literal: true 

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new(options)
  manager.download(options) if options[:download] || options[:auto]
  manager.store if options[:store]
  manager.store_img(options) if options[:store_img] || options[:auto]
rescue StandardError => e
  Hamster.logger.error(e.full_message)
  report to: 'D053YNX9V6E', message: "554: #{e}"
  exit 1
end
