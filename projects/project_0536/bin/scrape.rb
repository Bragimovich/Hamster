require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new

    if options[:download].present?
      manager.download
    elsif options[:store]
      manager.store
    end
  rescue Exception => e
    report(to: 'Abdur Rehman', message: "Project 536 Error:\n#{e.full_message}", use: :slack)
  end
end
