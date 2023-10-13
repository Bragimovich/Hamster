# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  begin
    Manager.new.download_and_update_licenses
  rescue StandardError => e
    Hamster.logger.error('inside outer rescue')
    Hamster.logger.error(e)
  end
end