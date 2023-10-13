# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    if options[:download]
      Manager.new.run_script
    end
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    report(to: 'UK50M4K3R', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
