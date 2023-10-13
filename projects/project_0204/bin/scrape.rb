# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../models/us_dept_ways_and_means_runs'
require_relative '../models/us_dept_ways_and_means'

def scrape(options)
  begin
    Scraper.new.scrape
  rescue Exception => e
    Hamster.logger.error("Exception: #{e.full_message}")
    report(to: 'U03CPDD648Y', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
