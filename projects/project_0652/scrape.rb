# frozen_string_literal: true
require_relative 'lib/manager'
LOGFILE = "project_0652.log"

def scrape(options)
  begin
    manager = Manager.new
    manager.update_run_id = options[:update_run_id] unless options[:update_run_id].nil?
    manager.start_date = options[:start_date] unless options[:start_date].nil?
    manager.end_date = options[:end_date] unless options[:end_date].nil?
    
    if options[:download]
      manager.download_by_lastname
    elsif options[:store]
      manager.store
    elsif options[:download_pdfs]
      manager.download_activities_pdfs
    elsif options[:auto]
      manager.download_by_lastname
      manager.download_activities_pdfs
      manager.store
    elsif options[:move_pdfs_to_aws]
      manager.move_pdfs_to_aws
    end
    
  rescue Exception => e
    Hamster.logger.error e.full_message
    Hamster.report(to: 'Jaffar Hussain', message: e.full_message)
  end 
end
