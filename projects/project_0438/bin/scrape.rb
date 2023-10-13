require_relative '../lib/pa_philadelphia_court_manager'

def scrape(options)
  manager = PaPhiladelphiaCourtManager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  elsif options[:auto]
    manager.download
    manager.store
  end
rescue => error
  logger.info error
  report(to: 'Eldar Eminov', message: "##{project_number} | #{error}", use: :both)
end
