# frozen_string_literal: true
require_relative '../project_0827/lib/manager'

def scrape(options)
  begin
    Hamster.report(to: 'Mashal Ahmad', message: "project_0827: Started Scraping!")
    Manager.new.scrape
    Hamster.report(to: 'Mashal Ahmad', message: "project_0827: Scraping Done!")
  rescue Exception => e
    Hamster.report(to: 'Mashal Ahmad', message: "project_0827:\n#{e.full_message}")
  end
end

