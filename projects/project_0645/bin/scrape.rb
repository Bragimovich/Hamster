# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    if options[:download]
      Manager.new.run
    elsif options[:complete_download]
      Manager.new.download
    elsif options[:upload]
      Manager.new.upload
    end
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'U04N76ASQHW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end

