require_relative '../lib/us_dos_beba_manager'

def scrape(options)
  manager = UsDosBebaManager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  else
    manager.download
    manager.store
  end
rescue => error
  Hamster.logger.error error.message.red
  Hamster.logger.error error.backtrace
  Hamster.logger.error "#{'#'*100}".red
  Hamster.report(to: 'Eldar Eminov', message: "##{Hamster.project_number} | #{error}", use: :both)
end
