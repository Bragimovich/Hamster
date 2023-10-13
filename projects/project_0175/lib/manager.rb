# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

FMC_URL = 'https://www.fmc.gov'
WEBSITE_URL = "#{FMC_URL}/category/news-releases/"

class US_FMC_Manager < Hamster::Harvester
  def scrape_pr
    scraper = Scraper.new
    parser = Parser.new
    article_list = parser.parse_pr_list(scraper.get_source(WEBSITE_URL))
    article_list.each do |link|
      pr_response = scraper.get_source(link)
      Keeper.new.store(parser.parse_single_pr(link, pr_response))
    end
  end
end
