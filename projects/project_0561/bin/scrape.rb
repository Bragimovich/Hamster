require_relative '../lib/manager'

def scrape(options)
  begin  
    manager = Manager.new
    if options[:download].present?
      manager.download(options)
    elsif options[:store].present?
      manager.store(options)
    else
      manager.download(options)
      manager.store(options)
    end
  rescue StandardError => e
    report(to: 'Shahrukh Nawaz', message: "Error in project 561: #{e.full_message}", use: :slack)
  end

end