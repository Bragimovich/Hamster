require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    if options['download']
      manager.download(options)
    elsif options['store']
      manager.store(options)
    else
      manager.download(options)
      manager.store(options)
    end
  rescue StandardError => e
    Hamster.logger.error e.full_message
  end
end
