#  frozen_string_literal: true

require_relative './lib/manager'

def scrape(options)
  begin
    if options[:download]
      Manager.new.download
    elsif options[:store]
      Manager.new.store
    elsif options[:cron]
      Manager.new.cron
    end
  rescue Exception => e
    Hamster.logger.error e.full_message
    Hamster.report(to: 'Muhammad Qasim', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
