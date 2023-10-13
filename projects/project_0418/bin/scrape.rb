# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)

  manager = Manager.new

  if options[:download].present?
    report(to: 'Abdur Rehman', message: "Download Started 418", use: :slack)
    link = options[:link] || nil
    manager.download(link)
    report(to: 'Abdur Rehman', message: "Download Ended 418", use: :slack)
  elsif options[:store]
    report(to: 'Abdur Rehman', message: "Store Started 418", use: :slack)    
    manager.store
    report(to: 'Abdur Rehman', message: "Store Ended 418", use: :slack)    
  elsif options[:daily_sync]
    report(to: 'Abdur Rehman', message: "Daily sync download and store started 418", use: :slack)
    manager.download_and_store
    report(to: 'Abdur Rehman', message: "Daily sync download and store ended 418", use: :slack)
  end
end