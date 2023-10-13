require_relative '../lib/manager'

def scrape(options)
  begin
    manager = Manager.new
    if options[:download]
      manager.run
    elsif options[:store]
      manager.store
    end
  rescue Exception => e
    Hamster.logger.error(e.full_message)
    Hamster.report(to: 'UK50M4K3R', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
