# frozen_string_literal: true
require_relative '../lib/manager'

LOGFILE = 'project_0564.log'

def scrape(options)
  log_dir  = "log/fsingh/#{Hamster::PROJECT_DIR_NAME}_#{@project_number}/"
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
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'Farzpal Singh', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end

end
