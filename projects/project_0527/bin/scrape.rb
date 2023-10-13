# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  end
rescue => e
  Hamster.logger.error "#{e}".red
  Hamster.logger.error e.full_message
  Hamster.logger.error "#{'#'* 100}".red
  Hamster.report(to: 'Eldar Eminov', message: "##{Hamster.project_number} | #{e}", use: :both)
end