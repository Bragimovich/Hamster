# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  manager = OpenSecretsManager.new
  manager.parse if options[:parse] || options[:auto]
  manager.store if options[:store] || options[:auto]
rescue StandardError => e
  report to: 'U03F2H0PB2T', message: "woke_project__opensecrets EXCEPTION: #{e}"
  puts ['*'*77,  e.backtrace]
  exit 1
end
