# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'

PDF_URL = "https://www2.erie.gov/sheriff/sites/www2.erie.gov.sheriff/files/uploads/data/InmateList.pdf"

class Manager < Hamster::Harvester
  attr_accessor :parser, :keeper, :scraper

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def store
    pdf = scraper.download(PDF_URL)
    parsing_pdf = parser.parse_pdf(pdf)
    keeper.insert_arrest(parsing_pdf)
    keeper.finish
  end
end
