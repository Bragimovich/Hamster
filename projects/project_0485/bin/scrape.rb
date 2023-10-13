# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)

  begin
    manager = Manager.new

    if options[:download]
      manager.download
    elsif options[:store]
      manager.store
    else
      manager.download
      manager.store
    end

  rescue => e
    Hamster.report(to: 'U02JPKC1KSN', message: "project-#{Hamster::project_number}: #{e.message}\n#{e.backtrace}")
    Hamster.logger.error(e.full_message)
    exit 1
  end 
end
