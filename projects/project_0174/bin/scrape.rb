require_relative '../lib/manager'
def scrape(options)
  manager = Manager.new
  if options['download']
    manager.download(options)
  elsif options['store']
    manager.store(options)
  else
    manager.download(options)
    manager.store(options)
  end
end
