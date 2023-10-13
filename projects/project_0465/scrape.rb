# frozen_string_literal: true
require_relative 'lib/maxpreps_com_manager'

def scrape(options)
  manager = MaxprepsComManager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  end
end
