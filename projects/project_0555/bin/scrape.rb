require_relative '../lib/manager'

def scrape(options)
  manager = Manager.new(higher_court: 316, lower_court: 429)

  begin
    report(to: 'Robert Arnold', message: "Download Started 555", use: :slack)
    manager.download
    report(to: 'Robert Arnold', message: "Download ended 555", use: :slack)
  rescue Exception => e
    Hamster.log.debug e.full_message
    report(to: 'Robert Arnold', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end