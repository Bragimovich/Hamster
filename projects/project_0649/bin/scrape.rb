# frozen_string_literal: true
require_relative '../lib/manager.rb'

def scrape(options)
  begin
    if options[:store]
      Manager.new.store
    else
      Manager.new.run
    end
  rescue  StandardError => e
    report to: 'Muhammad Musa', message: "Project 649 court_cases : #{e}"
    Hamster.logger.error(e.full_message)
  end
end
