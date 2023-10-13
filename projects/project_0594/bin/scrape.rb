require_relative '../lib/manager'
LOGFILE = "project_0594.log"

def scrape(options)
  manager = Manager.new
  
  if options[:download]
    manager.download
  elsif options[:store]
    manager.store
  elsif options[:auto]
    manager.download
    Hamster.logger.debug "will start after 5 sec ..."
    manager.store
  elsif options[:update]
    manager.download(update: true)
    Hamster.logger.debug "will start after 5 sec ..."
    sleep 5
    manager.store(update: true)
  else
    Hamster.logger.debug "No parameters specified. Try again."
  end

rescue Exception => e
  Hamster.logger.error e.full_message
  report(to: 'Robert Arnold', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
end