# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    Manager.new.scrape
  rescue => e
    Hamster.report(to: 'U02JPKC1KSN', message: "project_0642:\n#{e.full_message}")
    puts e.full_message
    exit 1
  end
end

