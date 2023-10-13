# frozen_string_literal: true

# frozen_string_literal: true
require_relative '../lib/manager'

LOGFILE = 'project_0728.log'

def scrape(options)
  begin
    if options[:download]
      Manager.new.download
    elsif options[:store]
      Manager.new.store
    end
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'Farzpal Singh', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end

end
