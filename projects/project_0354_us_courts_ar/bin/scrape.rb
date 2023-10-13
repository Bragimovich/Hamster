# frozen_string_literal: true

require_relative '../lib/car_manager'
OLEKSII_KUTS              = 'U03F2H0PB2T'
STARS = "\n#{'*'*77}"
COURTS = {304=>'SC%20-%20SUPREME%20COURT',
          406=>'CA%20-%20COURT%20OF%20APPEALS'}

def clear_log
  File.open(logger.instance_variable_get(:@logdev).filename, 'w') {}
end

def scrape(options)
  clear_log if options[:clear_log]
  logger.info("#{STARS}\n project_#{Hamster::project_number} started#{STARS}")

  COURTS.each_key do |court_id|
    ARSaacCaseManager.new(work:'g', court_id: court_id) if @arguments[:download]
    ARSaacCaseManager.new(work:'g', court_id: court_id, update:1) if @arguments[:update]
    ARSaacCaseManager.new(work:'s', court_id: court_id) if @arguments[:store]
  end

  logger.info("#{STARS}\n project_#{Hamster::project_number} finished#{STARS}")
rescue StandardError => e
  [STARS,  e].each {|line| logger.fatal(line)}
  report to: OLEKSII_KUTS, message: "354_ar_saac_case EXCEPTION: #{e}"
  exit 1
end
