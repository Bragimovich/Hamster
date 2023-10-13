require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new

    if options[:store]
      manager.store  
    else
      manager.store  
    end

  rescue Exception => e
    puts e.full_message
    #report(to: 'U02JPKC1KSN', message: "#{e.full_message}", use: :slack)
    puts ['*'*77, e.backtrace]
  end 
end
