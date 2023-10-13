# frozen_string_literal: true 

require_relative '../lib/manager'

def scrape(options)
  option = {}
  manager = Manager.new(options)
  manager.download(options) if options[:download] || options[:auto]
  manager.store(options) if options[:store]
  manager.update_desc(option.merge!({update_description: true})) if options[:auto] || options[:update] || options[:update_desc]
  manager.update_aws(options) if options[:auto] || options[:update] || options[:update_aws]
rescue StandardError => e
  Hamster.logger.error(e.full_message)
  report to: 'D053YNX9V6E', message: "65: #{e.full_message}"
  exit 1
end
