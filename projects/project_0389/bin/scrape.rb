require_relative '../lib/pa_sc_case_manager'

def scrape(options)
  manager = PaScCaseManager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  elsif options[:auto]
    manager.download
    manager.store
  end
rescue => error
  logger.info "#{error} | #{error.backtrace}".red
  report(to: 'Eldar Eminov', message: "##{project_number} | #{error}", use: :both)
end