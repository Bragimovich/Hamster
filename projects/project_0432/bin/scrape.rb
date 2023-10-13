# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    manager.run
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
