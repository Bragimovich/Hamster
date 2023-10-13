# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  begin
    if options[:download_info]
      Manager.new.download_info
    elsif options[:download_price]
      Manager.new.download_price
    elsif options[:download_equities]
      Manager.new.download_equities
    elsif options[:store_equities]
      Manager.new.store_equities
    elsif options[:store]
      Manager.new.store
    end
  rescue Exception => e
    Hamster.logger.error("Error: #{e.full_message}")
    Hamster.report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
