# frozen_string_literal: true

require_relative '../models/philadelphia_crime_stats_reports'
require 'google_drive'

class Scraper <  Hamster::Scraper

  def initialize
    super  
    @processed_weeks = PhiladelphiaCrimeStatsReports.where(:year => Date.today.year).pluck(:week_number)
  end

  def download
    year = Date.today.year
    credentials = Google::Auth::UserRefreshCredentials.new(Storage.new.auth)
    session = GoogleDrive::Session.from_credentials(credentials)
    folder = session.file_by_id("1NnwLSzGtjKhtr3nF68fLMKEkyebylIbN")
    folder.files.each_with_index do |file|
      file_id = file.id
      file_name = file.title
      next if @processed_weeks.include? file_name.split.last[0..1].to_i
      p file_name
      FileUtils.mkdir_p("#{storehouse}store/#{year}")
      FileUtils.touch("#{storehouse}store/#{year}/#{file_name.split.join("_")}")
      file.download_to_file("#{storehouse}store/#{year}/#{file_name.split.join("_")}")
    end
  end
end
