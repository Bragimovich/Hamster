# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

OLD_URL = 'https://republicans-naturalresources.house.gov/newsroom/'
URL = 'https://naturalresources.house.gov/news/'
WEBSITE_URL = "#{URL}documentquery.aspx?Page=1"
URL_CHANGE_DATE = Date.strptime('2022-12-31')

class RepublicansNaturalResourcesManager < Hamster::Harvester
  def initialize
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def scrape_pr
    article_list = @parser.parse_pr_list(@scraper.get_source(WEBSITE_URL))
    article_list.each do |article_data|
      pr_response = @scraper.get_source(article_data[:link])
      @keeper.store(@parser.parse_single_pr(article_data, pr_response))
    end
  end
end
