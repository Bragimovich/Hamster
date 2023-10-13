# frozen_string_literal: true
require_relative '../lib/manager.rb'

def scrape(options)
  begin
    Manager.new.run
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'U04MKV2QWQ4', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
