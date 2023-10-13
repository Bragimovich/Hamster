# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  
  manager = Manager.new
  year = options[:year]
  if year.nil?
    year = Date.today.year
  end

  if options[:auto]
    manager.download
    manager.store(year)
  elsif options[:download]
    manager.download
  elsif options[:store]
    manager.store(year)
  end

rescue StandardError => e
  report to: Manager::WILLIAM_DEVRIES, message: "Task#558 Scrape(options) function EXCEPTION: #{e}"
  exit 1

end
