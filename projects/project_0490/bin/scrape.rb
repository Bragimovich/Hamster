# frozen_string_literal: true

require_relative '../lib/il_dupage__manager'

def scrape(options)

  manager = IlDuPageManager.new

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
  Hamster.report message: "Project #0490 => scrape.rb:\n#{e.inspect}", to: 'U031HSK8TGF'
end
