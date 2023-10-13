require_relative '../lib/manager.rb'

def scrape(options)
  begin	
    manager = Manager.new
    if options[:download]
      manager.download
    elsif options[:store]
      manager.store
    end
  rescue Exception => e
    Hamster.logger.error("Error: #{e.full_message}")
  end
end
