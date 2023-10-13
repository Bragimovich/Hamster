# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  begin
    if options[:download]
      manager.download
    elsif options[:store]
      manager.store
    end
  rescue Exception => e
    p e.full_message
    Hamster.report(to: 'U04MHBYU5R9', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
