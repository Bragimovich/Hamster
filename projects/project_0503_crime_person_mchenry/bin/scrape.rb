# frozen_string_literal: true 

require_relative '../lib/manager_crime_data'

def scrape(options)
  ManagerCrimeData.new(**options)
end
