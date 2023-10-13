# frozen_string_literal: true
# ruby hamster.rb --grab=636 --debug --auto --year=2019
require_relative '../lib/manager'

def scrape(options)

  manager = Manager.new
  begin
    manager = Manager.new
    
    if options[:year].nil?
      year = Date.today.year
    else
      year = options[:year]
    end

    if options[:auto]
      manager.download_and_store_with_opinion_pdf(year)
      manager.download_dockets_for(year)
      manager.store_with_docket_pdf
      manager.clear_docket_pdfs
    elsif options[:download]
      manager.download_dockets_for(year)
    elsif options[:store]
      manager.download_and_store_with_opinion_pdf(year)
      manager.store_with_docket_pdf
      manager.clear_docket_pdfs
    end
  rescue Exception => e
    Hamster.report(to: Manager::FRANK_RAO_ID, message: "project-#{Hamster::project_number}. #{e.full_message}", use: :slack)
  end 
end
