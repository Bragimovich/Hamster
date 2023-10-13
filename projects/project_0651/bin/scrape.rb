# frozen_string_literal: true
require_relative '../lib/manager.rb'

def scrape(options)

  begin
    if options[:download]
      Manager.new.run(ARGV.last)
    end
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'U04MEH7MT1B', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
