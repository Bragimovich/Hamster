require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new

    if options[:download].present?
      report(to: 'Abdur Rehman', message: "Download Started 727", use: :slack)
      manager.download
      report(to: 'Abdur Rehman', message: "Download ended 727", use: :slack)
    elsif options[:store]
      report(to: 'Abdur Rehman', message: "Store started 727", use: :slack)
      manager.store
      report(to: 'Abdur Rehman', message: "Store Ended 727", use: :slack)
    end
  rescue Exception => e
    report(to: 'Abdur Rehman', message: "Project 727 Error:\n#{e.full_message}", use: :slack)
  end
end
