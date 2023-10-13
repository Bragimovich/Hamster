# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  manager.api if  options[:api]
  manager.download if options[:download] || options[:auto]
  manager.parse if options[:parse] || options[:auto]
  manager.store(options[:update]) if options[:store] || options[:auto]
rescue StandardError => e
  [STARS,  e].each {|line| logger.fatal(line)}
  report to: OLEKSII_KUTS, message: "516_nc_saac_case EXCEPTION: #{e}"
  exit 1
end
