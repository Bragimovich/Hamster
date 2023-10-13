# frozen_string_literal: true

require_relative '../lib/scraper.rb'
require_relative '../lib/store.rb'

def scrape(options)
  begin
    if options[:scrape]
      begin
        Scraper.new.main
      rescue Exception => e
       report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
    elsif options[:upload_file]
      Store.new.download
    end
  rescue Exception => e
   report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
