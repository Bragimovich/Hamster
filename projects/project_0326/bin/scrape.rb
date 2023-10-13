require_relative '../lib/us_dhs_fema_manager'

def scrape(options)
  manager = UsDhsFemaManager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  else
    manager.download
    manager.store
  end
rescue => error
  Hamster.logger.error "#{error} | #{error.backtrace}"
  Hamster.report(to: 'Eldar Eminov', message: "##{Hamster.project_number} | #{error}", use: :both)
end

