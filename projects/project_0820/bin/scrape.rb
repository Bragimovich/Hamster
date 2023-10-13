# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  begin
    Manager.new.run
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'Muhammad Musa', message: "project_820:\n#{e.full_message}")
  end
end
