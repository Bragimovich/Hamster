# frozen_string_literal: true
require_relative '../project_0730/lib/manager'
def scrape(options)
  Hamster.report(to: 'Mashal Ahmad', message: "project_0730: Parsing and storing Started!")
  manager = Manager.new  
  manager.process_store
  Hamster.report(to: 'Mashal Ahmad', message: "project_0730: Parsing and storing Done!")
rescue Exception => e
  Hamster.report(to: 'Mashal Ahmad', message: "project_0730:\n#{e.full_message}")  
end