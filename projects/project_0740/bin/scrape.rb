# frozen_string_literal: true
require_relative '../lib/manager'


def scrape(options)

  begin
    if options[:download]
      Manager.new.download
    elsif options[:download_missing]
      Manager.new.download_missing
    elsif options[:download_latest]
      Manager.new.download_latest
    elsif options[:store]
      Manager.new.store
    end
  rescue Exception => e
    Hamster.logger.debug e.full_message
    Hamster.report(to: 'Abdul Wahab', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end

