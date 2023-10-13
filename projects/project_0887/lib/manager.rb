# frozen_string_literal: true

require_relative 'scraper'
require_relative 'keeper'
require_relative 'parser'

class Manager < Hamster::Harvester
  attr_accessor :parser, :keeper, :scraper

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def store
    url = "https://www.monroecounty.gov/files/inmate/roster.pdf"
    file_pdf = scraper.fetch_pdf(url)
    parsing_pdf = parser.parse_pdf(file_pdf)
    keeper.insert_data(parsing_pdf)
    file = "#{storehouse}/store/#{url.split('/').last}"
    File.delete(file) if File.exist?(file)
    keeper.finish
  end
end
