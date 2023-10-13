# frozen_string_literal: true

require_relative '../lib/parser'

def scrape(options)
  begin
    parser = Parser.new

    if options[:active]
      parser.press_release_scraper
    elsif options[:archive]
      parser.news_archive_scraper
    end
  rescue Exception => e
   report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
