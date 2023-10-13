# frozen_string_literal: true
require_relative './lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    if options[:download]
      manager.download
    elsif options[:store]
      manager.finished =  options[:finished] unless options[:finished].nil?
      manager.store
    elsif options[:auto]
      manager.download
      manager.store
    end
    
  rescue Exception => e
    Hamster.logger.debug e.full_message
    Hamster.report(to: 'Jaffar Hussain', message: "#737 #{e.full_message}" , use: :slack)
  end 
end
