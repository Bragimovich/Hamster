# frozen_string_literal: true

require 'roo'
require_relative '../models/new_york_city_crime_statistics_weekly'
require_relative 'crime_complaints'
require_relative 'historical_perspective'
SUBFOLDER = 'new_york_city_crime_statistics_weekly/'

class NYCrimeStatParser < Hamster::Parser
  TEN_MINUTES = 600

  def initialize
    super
  end

  def store
    path = "#{ENV['HOME']}/HarvestStorehouse/project_0089/store/#{SUBFOLDER}cs-en-us-city.xlsx"
    xlsx = Roo::Spreadsheet.open(path)
    @sheet = xlsx.sheet(0)
    crime_complaints = CrimeComplaints.new(@sheet)
    historical_perspective = HistoricalPerspective.new(@sheet)
    
    crime_complaints.run
    historical_perspective.run
  end
end
