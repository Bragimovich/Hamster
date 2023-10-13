# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

URL = 'https://www.sba.gov'
JSON_PAGE = "#{URL}/api/content/search/articles.json?sortBy=Authored%20on%20Date&start=0&end="
EXTRA_ARTICLES = 50
PAGE = "#{URL}/articles?sortBy=Authored%20on%20Date&page="
MAX_PAGE_NUMBER = 5

class SmallBusinessAdministrationManager < Hamster::Harvester
  def initialize
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def parse
    # response = @scraper.get_source("#{JSON_PAGE}#{EXTRA_ARTICLES}")
    # json = @parser.get_json(response)
    0.upto(MAX_PAGE_NUMBER) do |page_number|
      response = @scraper.get_source("#{PAGE}#{page_number}")
      json = @parser.get_alternative_json(response)
      json["items"].reject! {|el| @keeper.exists?(el)}
      json["items"].each { |item| @keeper.store(@parser.parse(item)) }
    end
  end
end
