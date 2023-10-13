# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)

  if options[:download_csv_file]
    begin
      Manager.new.download_csv_file
    rescue StandardError => e
      Hamster.logger.debug e.full_message
      Hamster.report(to: 'Abdul Wahab', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
    end
  elsif options[:store_csv_file]
    begin
      Manager.new.store_csv_file
    rescue StandardError => e
      Hamster.logger.debug e.full_message
      #Hamster.report(to: 'Abdul Wahab', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
    end
  end
end
