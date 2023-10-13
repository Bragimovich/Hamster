# frozen_string_literal: true

require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  end
rescue => e
  Hamster.report(to: 'vyacheslav pospelov', message: "Project # 0119: Error - \n#{e.full_message} ", use: :both)
  logger.info  e.full_message
end