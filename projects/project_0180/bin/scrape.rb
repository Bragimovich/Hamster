# frozen_string_literal: true

require_relative '../lib/gasbuddy_manager'

def scrape(options)
  manager = GasBuddyManager.new
  manager.start
rescue => e
  puts e, e.full_message
  Hamster.report(to: 'Alim Lumanov', message: "Project #180 - scrape.rb:\n#{e}")
end
