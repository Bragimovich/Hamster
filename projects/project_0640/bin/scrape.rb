# frozen_string_literal: true 

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  
  if options[:download_case_accepted]
    report(to: "Hatri", message: "Starting run project 640: case_accepted", use: :slack)
    manager.download_case_accepted
    report(to: "Hatri", message: "Download case accepted task 640 done", use: :slack)
  elsif options[:download_case_opinion]
    report(to: "Hatri", message: "Starting run project 640: case_opinion", use: :slack)
    manager.download_case_opinion
    report(to: "Hatri", message: "Download case opinion task 640 done", use: :slack)
  else
    report(to: "Hatri", message: "Starting Run project 640", use: :slack)
    manager.download_case_accepted
    manager.download_case_opinion
    report(to: "Hatri", message: "Running project 640 done", use: :slack)
  end
rescue StandardError => e
  report to: 'Hatri', message: "640: #{e.full_message}"
  exit 1
end
