# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    if options[:download]
      Manager.new.run(ARGV.last)
    elsif options[:store]
      Manager.new.store
    end
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'U04MKV2QWQ4', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
