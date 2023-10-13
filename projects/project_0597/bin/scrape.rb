# frozen_string_literal: true

require_relative '../lib/manager'

LOGFILE = 'project_0597.log'

def scrape(options)
  begin
    if options[:download]
      Manager.new.download
    elsif options[:store]
      Manager.new.store
    end
  rescue Exception => e
    p e.full_message
    Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
