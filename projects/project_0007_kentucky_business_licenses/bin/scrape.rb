# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  # Hamster.report(to: 'Frank Rao', message: "#{@project_number} Started", use: :slack)
  begin
    from_keyword = 'aaaa'
    if options[:from]
      from = options[:from]
    end

    to_keyword = 'zzzz'
    if options[:to]
      from = options[:to]
    end
    
    manager = Manager.new
    manager.resume_running
  rescue Exception => e
    logger.debug e.full_message
    # Hamster.report(to: 'Frank Rao', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end 
end
