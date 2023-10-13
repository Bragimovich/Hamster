# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    if options[:download]
      manager.download
    elsif options[:store]
      manager.store
    elsif options[:update]
      manager.download
      manager.store
    end
  rescue Exception => e
    Hamster.report(to: 'dmitiry.suschinsky', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
