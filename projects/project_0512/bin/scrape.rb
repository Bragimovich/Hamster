# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download].present?
    report(to: 'Abdur Rehman', message: "Download Started 512", use: :slack)
    manager.download
    report(to: 'Abdur Rehman', message: "Download ended 512", use: :slack)
  elsif options[:store]
    report(to: 'Abdur Rehman', message: "Store started 512", use: :slack)
    manager.store
    report(to: 'Abdur Rehman', message: "Store Ended 512", use: :slack)
  end
end