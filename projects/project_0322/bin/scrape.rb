# frozen_string_literal: true

require_relative '../lib/fac_democrats.rb'
require_relative '../lib/fac_republicans.rb'

def scrape(options)
  begin
    if options[:democrat]
      FacDemocrats.new.main
    elsif options[:republic]
      FacRepublicans.new.main
    end
  rescue Exception => e
    Hamster.report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
  end
end
