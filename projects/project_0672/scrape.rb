#  frozen_string_literal: true

require_relative './lib/manager'

LOGFILE = 'project_0672.log'

def scrape(options)
  log_dir  = "log/#{Hamster::PROJECT_DIR_NAME}_#{@project_number}/"
  log_path = "#{log_dir}#{LOGFILE}"
  FileUtils.mkdir_p(log_dir)
  File.open(log_path, 'a') { |file| file.puts Time.now.to_s }
  begin
    Manager.new.main
  rescue Exception => e
    p e.full_message
    Hamster.report(to: 'Muhammad Qasim', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
