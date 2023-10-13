# frozen_string_literal: true
require_relative './lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    if options[:download]
      manager.download
    elsif options[:store]
      manager.store
    elsif options[:auto]
      manager.download
      manager.store
    end
    
  rescue Exception => e
    Hamster.logger.error e.full_message
    Hamster.report(to: 'Jaffar Hussain', message: e.full_message)
  end 
end

