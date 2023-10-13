# frozen_string_literal: true
require_relative '../lib/manager.rb'
LOGFILE = "mn_public_employee_salaries_roaster.log"

def scrape(options)
  
  log_dir  = "log/#{Hamster::PROJECT_DIR_NAME}_#{@project_number}/"
  log_path = "#{log_dir}#{LOGFILE}"
  
  FileUtils.mkdir_p(log_dir)
  File.open(log_path, 'a') { |file| file.puts Time.now.to_s}

  begin
    if options[:download]
      Manager.new.download
    elsif options[:store]
      Manager.new.store
    end
  rescue Exception => e
    Hamster.report(to: 'UK50M4K3R', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
