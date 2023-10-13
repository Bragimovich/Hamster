# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    scraper = Manager.new
    scraper.main(options[:year])
  rescue Exception => e
    Hamster.report(to: 'dmitiry.suschinsky', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
