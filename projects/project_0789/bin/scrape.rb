require_relative '../lib/manager.rb'

def scrape(options)
	Manager.new.download
end
