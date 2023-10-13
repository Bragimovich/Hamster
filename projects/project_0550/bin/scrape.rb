# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  manager.download
rescue StandardError => e
  report to: 'Gabriel Carvalho', message: "550: #{e.full_message}"
  puts ['*' * 77, e.backtrace]
  exit 1
end
