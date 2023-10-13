# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download].present?
    report(to: 'Abdur Rehman', message: "Download Started 196", use: :slack)    
    manager.download
    report(to: 'Abdur Rehman', message: "Download Ended 196", use: :slack)
  elsif options[:store]
    report(to: 'Abdur Rehman', message: "Store Started 196", use: :slack)    
    manager.store
    report(to: 'Abdur Rehman', message: "Store Ended 196", use: :slack)    
  end
end