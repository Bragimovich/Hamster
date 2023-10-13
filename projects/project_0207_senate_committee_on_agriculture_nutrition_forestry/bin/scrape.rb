# frozen_string_literal: true

require_relative '../lib/majority_minority.rb'

def scrape(options)
  begin
    if options[:majority]
      MajorityMinority.new.main(true)
    elsif options[:minority]
      MajorityMinority.new.main(false)
    end
  rescue Exception => e
    report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
