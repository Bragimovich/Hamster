require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    year = options[:year]
    if year.nil?
      year = Date.today.year
    end
    if options[:download].present?
      manager.download
    elsif options[:store]
      manager.store_for(year)
    end
  rescue Exception => e
    report(to: 'Frank Rao', message: "Project 539 Error:\n#{e.full_message}", use: :slack)
  end
end
