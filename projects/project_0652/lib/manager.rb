# frozen_string_literal: true

require_relative '../lib/scraper_browser'

require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/downloader'

class Manager < Hamster::Harvester
  attr_accessor :update_run_id, :start_date, :end_date
  include Downloader

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = ScraperBrowser.new
    @s3 = AwsS3.new(bucket_key = :us_court)
    @update_run_id = params[:update_run_id].nil? ? true : false
    @end_date = Date.today.strftime('%m/%d/%Y')
    @start_date = (Date.today - 7).strftime('%m/%d/%Y')
  end

  def download_by_lastname
    begin
        start_time = Time.new
        # scraper.start_browser
        ('a'..'z').to_a.map do|c|
            logger.debug "lastname #{c}, date range [#{@start_date},#{@end_date}]"
            existing_format = '%m/%d/%Y'
            (Date.strptime(@start_date, existing_format)..Date.strptime(@end_date, existing_format)).to_a.map do|date|
              d = date.strftime(existing_format)
              logger.debug "date range [#{d},#{d}]"
              record_count = download_cases(c,d,d)
              if record_count.to_i > 499
                logger.debug "narrow down search: lastname #{c}, date range [#{d},#{d}]"
              end
            end
        end
        end_time = Time.new
        total_time = (end_time - start_time)/3600
        logger.debug "total time #{total_time} hours"
        Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - #0652 Downloaded, total time #{total_time}" , use: :slack)
    rescue StandardError => e
      scraper.close_browser
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - Files Scraping Failed - #{msg}" , use: :slack)
    ensure
      scraper.close_browser
    end
  end

  def download_activities_pdfs
    begin
        start_time = Time.new
        logger.debug 'downloading pdf files'
        download_documents
        end_time = Time.new
        total_time = (end_time - start_time)/3600
        logger.debug "total time #{total_time} hours"
        Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - #0652 Downloaded PDFs, total time #{total_time}" , use: :slack)
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - PDF downloading failed - #{msg}" , use: :slack)
    end
  end

  def store
    begin
        start_time = Time.new
        problematic_cases = store_in_db(update_run_id)
        end_time = Time.new
        total_time = (end_time - start_time)/3600
        logger.debug "total time #{total_time} hours"
        msg = "#{Time.now} - #0652 Stored, run_id #{keeper.run_id} , total time #{total_time}, problematic cases #{problematic_cases.join(',')}"
        Hamster.report(to: 'Jaffar Hussain', message: msg , use: :slack)
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - Storing to db failed - #{msg}" , use: :slack)
    end

  end

  private

  attr_accessor :keeper, :parser, :scraper

end
