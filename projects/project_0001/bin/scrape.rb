require_relative '../lib/irs_non_profit_manager'

def scrape(options)
  manager = IrsNonProfitManager.new

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