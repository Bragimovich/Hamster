# frozen_string_literal: true

require_relative 'scraper'
require_relative 'parser'

class EnergyManager
  def initialize(**params)
  end

  def download_data
    scraper = EnergyScraper.new
    scraper.download
  end

  def store_data
    parser = EnergyParser.new('Energy')
    parser.store
  end
end

