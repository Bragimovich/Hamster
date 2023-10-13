require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  else
    manager.download
    manager.store
  end
rescue => error
  Hamster.logger.debug "#{error} | #{error.backtrace}".red
  Hamster.report(to: 'Eldar Eminov', message: "##{Hamster.project_number} | #{error}", use: :both)
end
