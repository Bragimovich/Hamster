# frozen_string_literal: true

require_relative 'parser'
require_relative 'scraper'
require_relative 'keeper'
URL = 'https://www.ntsb.gov/news/press-releases/Pages/ByYear.aspx'

class NTSBManager < Hamster::Harvester
  def download
    links = Parser.new.links(Scraper.new.get_source(URL))
    links[0..10].each {|link| Keeper.new.store(Parser.new.parse(link, Scraper.new.get_source(link)))}
  end
end
