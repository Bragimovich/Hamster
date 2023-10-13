require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new

  if options[:download].present?
    report(to: 'Abdur Rehman', message: "Download Started 477", use: :slack)
    manager.download
    report(to: 'Abdur Rehman', message: "Download ended 477", use: :slack)
  elsif options[:store]
    report(to: 'Abdur Rehman', message: "Store started 477", use: :slack)
    manager.store
    report(to: 'Abdur Rehman', message: "Store Ended 477", use: :slack)
  rescue Exception => e
    report(to: 'Abdur Rehman', message: "#{e.full_message}", use: :slack)
  end
end
  