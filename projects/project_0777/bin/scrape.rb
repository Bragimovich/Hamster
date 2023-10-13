# frozen_string_literal: true
require_relative '../lib/manager.rb'

def scrape(options)
  begin
    if options[:download]
      Manager.new.download
    elsif options[:store]
      Manager.new.store
    end
  rescue  StandardError => e
    report to: 'Muhammad Musa', message: "Project 777 k-12 salaries : #{e}"
    Hamster.logger.error(e.full_message)
  end
end
