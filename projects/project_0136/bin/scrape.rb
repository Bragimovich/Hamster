# frozen_string_literal: true

require_relative '../lib/scraper.rb'
require_relative '../lib/parser.rb'
LOGFILE = "us_dos.log"

def scrape(options)
  log_dir  = "log/#{Hamster::PROJECT_DIR_NAME}_#{@project_number}/"
  log_path = "#{log_dir}#{LOGFILE}"
  FileUtils.mkdir_p(log_dir)
  File.open(log_path, 'a') { |file| file.puts Time.now.to_s }
  begin
    if options[:download]
      Scraper.new.scraper
    elsif options[:store]
      Parser.new.store
    end
  rescue Exception => e
   report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
