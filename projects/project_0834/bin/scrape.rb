# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    Manager.new.download
  rescue Exception => e
    Hamster.logger.debug(e.full_message)
    Hamster.report(to: 'D053YNX9V6E', message: "834: #{e.full_message}")
  end
end
