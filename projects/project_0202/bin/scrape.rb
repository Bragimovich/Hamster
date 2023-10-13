# frozen_string_literal: true

require_relative '../lib/manager'
SCRAPER = OLEKSII_KUTS = 'U03F2H0PB2T'
STARS = "\n#{'*'*77}"

def clear_log
  File.open(logger.instance_variable_get(:@logdev).filename, 'w') {}
end

def scrape(options)
  clear_log if options[:clear_log]
  RepublicansNaturalResourcesManager.new.scrape_pr if options[:download] || options[:auto]
rescue StandardError => e
  [STARS,  e].each {|line| logger.fatal(line)}
  report to: SCRAPER, message: "republicans_naturalresources_house_gov_scrape EXCEPTION: #{e}"
  exit 1
end
