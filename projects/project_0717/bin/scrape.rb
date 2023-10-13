require_relative '../lib/manager'
def scrape(options)
  manager = Manager.new
  if options[:store]
    manager.store
  end
end
