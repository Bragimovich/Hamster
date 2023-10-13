# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  manager = MonkeypoxCDC.new
  manager.download if options[:download] || options[:auto]
  manager.parse if options[:parse] || options[:auto]
  manager.store if options[:auto]
rescue StandardError => e
  report to: 'U03F2H0PB2T', message: "monkeypox_CDC_tracker EXCEPTION: #{e}"
  puts ['*'*77, e.backtrace]
  exit 1
end
