# frozen_string_literal: true

require_relative '../lib/manager'
OLEKSII_KUTS = 'U03F2H0PB2T'
STARS = "\n#{'*'*77}"

def clear_log
  File.open(logger.instance_variable_get(:@logdev).filename, 'w') {}
end

def scrape(options)
  clear_log if options[:clear_log]
  logger.info("#{STARS}\n project_#{Hamster::project_number} started#{STARS}")

  manager = SCBAR_Manager.new
  manager.parse if options[:download] || options[:auto]
  manager.store if options[:store] || options[:auto]
  manager.fix if options[:fix]

  logger.info("#{STARS}\n project_#{Hamster::project_number} finished#{STARS}")
rescue StandardError => e
  [STARS,  e].each {|line| logger.fatal(line)}
  report to: OLEKSII_KUTS, message: "475_scbar_org_scrape EXCEPTION: #{e}"
  exit 1
end
