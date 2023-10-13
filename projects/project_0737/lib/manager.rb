# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/downloader'

class Manager < Hamster::Harvester
  attr_accessor :finished
  include Downloader
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
    @finished = true
  end

  def download
    begin
      start_time = Time.new
      # ('a'..'z').to_a.map do|first_name|
      first_name=""
      logger.debug("searching first name: #{first_name}, current_start: #{keeper.current_start}, run_id: #{keeper.run_id}")
      scraper.safe_connection {search_inmates(first_name,keeper.current_start)}
      # end
      end_time = Time.new
      total_time = (end_time - start_time)/3600
      logger.debug "total time #{total_time} hours"
      Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - #737 Downloaded, total time #{total_time}" , use: :slack)
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - #737 Files Scraping Failed - #{msg}" , use: :slack)
    end
  end

  def store
    begin
      start_time = Time.new
      store_in_db(@finished)
      end_time = Time.new
      total_time = (end_time - start_time)/3600
      logger.debug "total time #{total_time} hours"
      msg = "#{Time.now} - #737 Stored, run_id #{keeper.run_id} , total time #{total_time}"
      Hamster.report(to: 'Jaffar Hussain', message: msg , use: :slack)
    rescue StandardError => e
      msg = "#{e} | #{e.backtrace}"
      logger.error msg
      Hamster.report(to: 'Jaffar Hussain', message: "#{Time.now} - #737 Storing to db failed - #{msg}" , use: :slack)
    end

  end

  private

  attr_accessor :keeper, :parser, :scraper

end
