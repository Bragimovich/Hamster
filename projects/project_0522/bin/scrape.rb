# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new

    if options[:auto]
      manager.download
      manager.store
    elsif options[:download]
      manager.download
    elsif options[:store]
      manager.store  
    end

  rescue Exception => e
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number}. #{e.message}")
    Hamster.logger.error(e.full_message)
  end 
end

