require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  manager.download if options[:download]
rescue => e
  Hamster.logger.error "#{e} | #{e.full_message}"
end
