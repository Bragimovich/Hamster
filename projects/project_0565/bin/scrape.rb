require_relative '../lib/manager.rb'

def scrape(options)
  begin
    Manager.new.download
  rescue StandardError => e
    Hamster.logger.error('inside outer rescue')
    Hamster.logger.error(e)
  end
end
