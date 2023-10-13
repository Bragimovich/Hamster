# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download_and_store].present?
    report(to: 'Abdur Rehman', message: "Download and store Started 515", use: :slack)
    manager.download_and_store
    report(to: 'Abdur Rehman', message: "Download and store ended 515", use: :slack)
  end
end