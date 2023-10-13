# frozen_string_literal: true 

require_relative '../lib/manager'
require_relative '../lib/controller'
require_relative '../lib/photo_update'

def scrape(options)
  manager = Manager.new(options)
  manager.download_forecast if options[:download_forecast]
  manager.download_historical if options[:download_historical]
  #manager.load_city
  #manager.load_lat_lon
  #manager.update_time_zone
  #manager.store if options[:store] || options[:auto]
  Controller.new if options[:download_forecast]
  PhotoUpdate.new if options[:photo_update]
rescue StandardError => e
  report to: 'victor lynnyk', message: "530: #{e.full_message}"
  exit 1
end
