# frozen_string_literal: true
require_relative '../lib/manager.rb'

def scrape(options)
  manager = Manager.new
  manager.download_and_store
  report(to: "Hatri", message: "Download and storing data to DB project 725 finish", use: :slack)
rescue StandardError => e
  report to: 'Hatri', message: "project 725: #{e.full_message}"
  exit 1
end
