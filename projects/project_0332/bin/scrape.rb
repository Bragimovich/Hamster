# frozen_string_literal: true

require_relative '../lib/us_dept_pm_bureau_scraper'
require_relative '../lib/us_dept_pm_bureau_parser'

def scrape(options)
  scraper = UsDeptPmBureauScraper.new
  parser = UsDeptPmBureauParser.new

  if options[:download]
    scraper.start
  elsif options[:store]
    parser.start
  elsif options[:auto]
    scraper.start
    puts 'went to sleep for 5 sec ...'
    sleep 5
    parser.start
  else
    puts 'No parameters specified. Try again.'
  end

rescue StandardError => e
  puts e, e.full_message
  Hamster.report(to: 'U031HSK8TGF', message: "project_0332_error in scrape.rb:\n#{e.inspect}")
end