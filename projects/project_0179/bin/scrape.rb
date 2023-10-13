# frozen_string_literal: true

require_relative '../lib/manager'

LOGFILE = 'project_0179.log'

def scrape(options)
  begin
    timeout(3600 * 24 * 30){
      Manager.new(court_type: :ac).scrape if options[:ac_scrape]
      Manager.new(court_type: :dc).scrape if options[:dc_scrape]

      Manager.new(court_type: :ac).store if options[:ac_store]
      Manager.new(court_type: :dc).store if options[:dc_store]
    }
  rescue Timeout::Error => e
    Hamster.report(to: 'U04JS3K201J', message: "project_#{@project_number}:\n Timeout Error!")
  rescue StandardError => e
    puts e.full_message
    Hamster.report(to: 'U04JS3K201J', message: "project_#{@project_number}:\n#{e.full_message}")
  end
end
