require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  elsif options[:auto]
    manager.download
    manager.store
  end
rescue => error
  Hamster.logger.error error
  Hamster.report(to: 'Eldar Eminov', message: "##{Hamster.project_number} | #{error}", use: :both)
end