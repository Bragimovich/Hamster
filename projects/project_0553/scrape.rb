# frozen_string_literal: true
require_relative './lib/manager'

def scrape(options)

  begin
    if options[:download]
      Manager.new.download
    elsif options[:store]
      Manager.new.store
    end
  rescue Exception => e
    p e.full_message
    Hamster.report(to: 'Abdul Wahab', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
