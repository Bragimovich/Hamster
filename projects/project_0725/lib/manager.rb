# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'


class Manager < Hamster::Harvester
  attr_accessor :parser, :keeper, :scraper

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download_and_store
    grant_url = "https://www.gatesfoundation.org/about/committed-grants"
    csv_file = scraper.get_file_csv(grant_url)
    parsing_csv = parser.parse_csv(csv_file)
    keeper.insert_data(parsing_csv)
    keeper.update_data(parsing_csv)
    keeper.finish
  end
end

