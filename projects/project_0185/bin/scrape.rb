require_relative '../lib/mcc_manager'

def scrape(options)
  manager = MccManager.new

  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  else
    manager.download
    manager.store
  end
end
