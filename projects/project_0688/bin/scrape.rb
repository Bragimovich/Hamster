require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new
  begin
    report(to: 'U04JS3K201J', message: "Store started 688", use: :slack)
    if options[:download]
      manager.download(options)
    elsif options[:store]
      manager.store(options)
    else
      manager.scrape
    end
    report(to: 'U04JS3K201J', message: "Store Ended 688", use: :slack)
  rescue => e
    report(to: 'U04JS3K201J', message: "project_688:\n#{e.full_message}")
  end
end
