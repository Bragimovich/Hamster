# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download].present?
    report(to: 'Abdur Rehman', message: "Download Started 524", use: :slack)
    manager.daily_download
    report(to: 'Abdur Rehman', message: "Download ended 524", use: :slack)
  elsif options[:store]
    report(to: 'Abdur Rehman', message: "Store started 524", use: :slack)
    manager.daily_store
    report(to: 'Abdur Rehman', message: "Store Ended 524", use: :slack)
  end
end