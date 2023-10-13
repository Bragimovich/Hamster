require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  if options[:store_csv]
    manager.store_csv
  elsif options[:store_pdf]
    manager.store_pdf
  end
end

