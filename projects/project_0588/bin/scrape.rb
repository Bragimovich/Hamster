# frozen_string_literal: true
require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  begin
    if options[:download].present?
      manager.download
    elsif options[:store].present?
      manager.store
    end
  rescue Exception => e
    p e.full_message
  end
end
