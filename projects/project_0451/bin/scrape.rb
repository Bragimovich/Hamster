require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download].present?
    manager.download
  elsif options[:store]
    manager.store
  end
end
  