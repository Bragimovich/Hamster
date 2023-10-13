require_relative '../lib/wisc_courts_manager'

def scrape(options)
  manager = WiscCourtsManager.new
  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  elsif options[:save_aws]
    manager.save_activities_aws
  elsif options[:auto]
    manager.download
    manager.store
  end
rescue => error
  Hamster.logger.error "#{error} | #{error.backtrace}".red
  Hamster.report(to: 'Eldar Eminov', message: "##{Hamster.project_number} | #{error}", use: :both)
end
