# frozen_string_literal: true

require 'roo'
require_relative '../models/new_york_city_crime_statistics_weekly'

class NYCrimeStatScraper < Hamster::Scraper
  SOURCE = 'https://www.nyc.gov/assets/nypd/downloads/excel/crime_statistics/cs-en-us-city.xlsx'
  SUBFOLDER = 'new_york_city_crime_statistics_weekly/'

  def initialize
    super
  end
  
  def download
    filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}

    source = connect_to(SOURCE, proxy_filter: filter)
    result = source&.body

    save_xlsx(result)
  end


  def save_xlsx(xlsx)
    FileUtils.mkdir_p "#{ENV['HOME']}/HarvestStorehouse/project_0089/store/#{SUBFOLDER}"

    xlsx_storage_path = "#{ENV['HOME']}/HarvestStorehouse/project_0089/store/#{SUBFOLDER}cs-en-us-city.xlsx"

    File.open(xlsx_storage_path, "w") do |f|
      f.write(xlsx)
    end
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end

    response
  end
end
