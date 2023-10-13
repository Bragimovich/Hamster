# frozen_string_literal: true

require_relative '../lib/football_box_score__manager'

def scrape(options)

  manager = FootballManager.new
  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  elsif options[:auto]
    manager.download
    p 'went to sleep for 10 secs ...'
    sleep 10
    manager.store
  else
    p "No options specified. Finishing..."
  end

rescue StandardError => e
  puts e, e.full_message
  Hamster.report message: "Project #0513 => scrape.rb:\n#{e.inspect}", to: 'U031HSK8TGF'
end
