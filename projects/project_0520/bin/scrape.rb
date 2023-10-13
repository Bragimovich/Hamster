require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download].present?
    report(to: 'Abdur Rehman', message: "Download Started 520", use: :slack)
    manager.download
    report(to: 'Abdur Rehman', message: "Download ended 520", use: :slack)
  elsif options[:store]
    report(to: 'Abdur Rehman', message: "Store started 520", use: :slack)
    manager.store
    report(to: 'Abdur Rehman', message: "Store Ended 520", use: :slack)
  end
end