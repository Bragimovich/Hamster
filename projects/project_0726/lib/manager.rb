# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
  end

  def download
    begin
      scraper.safe_connection do
        start_time = Time.new
        csv = scraper.download_csv
        save_csv(csv) unless csv.nil?
        end_time = Time.new
        total_time = (end_time - start_time)/3600
        logger.debug "total time #{total_time} hours"
        Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - #726 Downloaded, total time #{total_time}" , use: :slack)
      end
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - Files Scraping Failed - #{msg}" , use: :slack)
    end
  end

  def store
    begin
      scraper.safe_connection do
        start_time = Time.new
        data = CSV.foreach(csv_path, headers: true).map(&:to_h)
        data.each do |hash|
          d = hash.transform_keys{ |key| key.to_s.downcase.gsub(" ","_") }
          d["data_as_of"] = parser.date_format(d["data_as_of"])
          d["data_source_url"] = scraper.data_source_url
          keeper.store(d)
        end
        keeper.finish
        end_time = Time.new
        total_time = (end_time - start_time)/3600
        logger.debug "total time #{total_time} hours"
        msg = "#{Time.now} - #726 Stored, run_id #{keeper.run_id} , total time #{total_time}"
        Hamster.report(to: 'Jaffar Hussain', message: msg , use: :slack)
      end
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - Storing to db failed - #{msg}" , use: :slack)
    end

  end

  private

  attr_accessor :keeper, :parser, :scraper

  def save_csv(content)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    File.open(csv_path, "wb") do |f|
      f.write(content)
    end
  end

  def csv_path
    file_path = "#{storehouse}store/#{keeper.run_id}/data.csv"
  end

end
