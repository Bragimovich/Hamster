# frozen_string_literal: true

require_relative '../lib/manager'

LOGFILE = 'project_0559.log'

def scrape(options)
  log_dir  = "#{Hamster::Harvester.new.storehouse}log/#{Hamster::PROJECT_DIR_NAME}_#{@project_number}/"
  log_path = "#{log_dir}#{LOGFILE}"
  FileUtils.mkdir_p(log_dir)
  File.open(log_path, 'a') { |file| file.puts Time.now.to_s }
  begin
    if options[:download]
      Manager.new.download
    elsif options[:store]
      Manager.new.store
    end
  rescue Exception => e
    p e.full_message
    Hamster.report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
