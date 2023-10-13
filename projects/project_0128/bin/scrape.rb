# frozen_string_literal: true

require_relative '../lib/manager'
LOGFILE = 'scrape_log_file.log'

def scrape(options)
  manager = Manager.new
  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  end
rescue Exception => e
  puts e.full_message
  report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
end
