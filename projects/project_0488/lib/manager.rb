# frozen_string_literal: true
require_relative 'scraper'
require_relative 'parser'
require_relative 'keeper'
require_relative '../models/il_will_runs'

class ILWillManager
  def initialize(options)
    @run = !options[:store] ? ILWillKeeper.new.assign_new_run : IlWillCrimeRuns.maximum(:id)
  end

  def download_data
    scraper = ILWillScraper.new(@run)
    scraper.download
  end

  def store_data
    parser = ILWillParser.new(@run)
    parser.store
  end
end
