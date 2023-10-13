# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  manager = GlobalDotHealthManager.new
  manager.download if options[:download] || options[:auto]
  manager.store if options[:store] || options[:auto]
rescue StandardError => e
  report to: 'U03F2H0PB2T', message: "monkeypox_globaldothealth_csv EXCEPTION: #{e}"
  puts ['*'*77,  e.backtrace]
  exit 1
end
