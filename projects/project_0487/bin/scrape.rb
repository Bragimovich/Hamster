require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  if options['download']
    manager.download
  elsif options['store']
    manager.store
  else
    manager.download
    manager.store
  end
end
