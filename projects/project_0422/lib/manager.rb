# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
URL = "https://download.cms.gov/nppes/"
PAGE = "NPI_Files.html"

class NppesNpiRegistry < Hamster::Harvester
  def initialize(options)
    super
    @parser = Parser.new(options)
    @scraper = Scraper.new(options)
    @keeper = Keeper.new
    @file_name = ""
  end

  def download
    @scraper.clear
    page = @scraper.get_source(URL + PAGE)
    @file_name = @parser.get_file_data(page)
    logger.info("Scraper Download Begin\n#{@file_name}")
    @scraper.download(@file_name)
    logger.info("Scraper Download END")
  end

  def store
    csv_src = Dir[storehouse + "store/*"].sort
    source = "#{URL}#{@file_name}"
    start_time = Time.now

    logger.info("#{start_time} Load Data...")
    @keeper.store(csv_src, source)
    logger.info("#{Time.now.to_s} Finish load data...")
    logger.info ("Store duration: #{(Time.now - start_time) / 60}")

    @scraper.clear
  end
end
