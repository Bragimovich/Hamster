require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  if options['download']
    manager.download(options)
  elsif options['store']
    manager.store
  else
    manager.download(options)
    manager.store
  end
end
