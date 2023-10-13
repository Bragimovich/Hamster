# frozen_string_literal: true

require_relative '../lib/scraper'

def scrape(options)
  begin
    if options[:download]
      Scraper.new.scraper
    elsif options[:parse]
      Scraper.new.store
    end
  rescue Exception => e
    report(to: 'U03CPDD648Y', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
