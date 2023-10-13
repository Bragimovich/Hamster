# frozen_string_literal: true
require_relative '../lib/manager.rb'

def scrape(options)
  begin
    if options[:download]
      Manager.new.run_script
    end
  rescue Exception => e
    Hamster.logger.error(e.message)
    Hamster.report(to: 'U04N1USUK1S', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
