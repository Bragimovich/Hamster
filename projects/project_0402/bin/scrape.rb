# frozen_string_literal: true

require_relative '../lib/scraper'

def scrape(options)
  begin
    Scraper.new.run_task
  rescue Exception => e
    report(to: 'UK50M4K3R', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
