# frozen_string_literal: true

require_relative '../lib/ftc_scraper'

def scrape(options)
  begin
    mian_class_obj = FederalTradeCommission.new
    mian_class_obj.main_scraper
  rescue Exception => e
    report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
