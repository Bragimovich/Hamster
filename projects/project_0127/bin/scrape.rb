# frozen_string_literal: true

require_relative '../lib/us_dos_scraper.rb'

def scrape(options)
  begin
    mian_class_obj = UsDeptOfState.new  
    mian_class_obj.press_release_scraper
  rescue Exception => e
    Hamster.logger.error("Error: #{e.full_message}")
    report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end  
end
