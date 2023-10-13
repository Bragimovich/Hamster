# frozen_string_literal: true
require_relative '../project_0847/lib/manager'

def scrape(options)
  begin
    #Hamster.report(to: 'Mashal Ahmad', message: "project_0847: Started Scraping!")
    Manager.new.scrape
    #Hamster.report(to: 'Mashal Ahmad', message: "project_0847: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'Mashal Ahmad', message: "project_0847:\n#{e.full_message}")
  end
end

