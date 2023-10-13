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

  manager = NCSaacCaseManager.new
  options[:weeks] ||= 1
  1.upto(options[:weeks]) do |weeks_ago|
    options[:weeks_ago] = weeks_ago + options[:shift].to_s.to_i
    logger.info(STARS + "\n" + JSON.pretty_generate(options))

    manager.download(**options) if options[:download] || options[:auto]
    manager.parse if options[:parse] || options[:auto]
    manager.store(options[:update]) if options[:store] || options[:auto]
  end
  manager.test if options[:test]

  logger.info("#{STARS}\n project_#{Hamster::project_number} finished#{STARS}")
rescue StandardError => e
  [STARS,  e].each {|line| logger.fatal(line)}
  report to: OLEKSII_KUTS, message: "516_nc_saac_case EXCEPTION: #{e}"
  exit 1
end
