# frozen_string_literal: true

require_relative '../lib/library_of_congress_scraper'

def scrape(options)
  begin
    mian_class_obj = LibraryOfCongressScraper.new
    mian_class_obj.main_parser
  rescue Exception => e
    report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
