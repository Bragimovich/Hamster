# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new

    if options[:auto].present?
      report(to: 'Abdur Rehman', message: "Auto Started 200", use: :slack)
      manager.download_and_store
      report(to: 'Abdur Rehman', message: "Auto ended 200", use: :slack)
    end
  rescue Exception => e
    report(to: 'Abdur Rehman', message: "Project 200 Error:\n#{e.full_message}", use: :slack)
  end
end