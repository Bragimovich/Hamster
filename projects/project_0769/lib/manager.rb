# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'

URL = "https://media.ethics.ga.gov/search/Campaign/Campaign_Name.aspx"

class Manager < Hamster::Harvester
  def initialize
    super
    @scraper = Scraper.new
    @keeper = Keeper.new
    @parser = Parser.new
  end

  def parse
    filer_ids = @keeper.filer_ids
    links = filer_ids.map {|el| generate_link(el)}
    candidate_links = links.reject {|el| el.end_with?('ee')}
    committee_links = links - candidate_links

    candidate_links.each {|link| @scraper.store_to_csv('candidate.csv', @parser.parse_candidate(@scraper.get_source(link)))}
    committee_links.each {|link| @scraper.store_to_csv('committee.csv', @parser.parse_committee(@scraper.get_source(link)))}
  end

  def generate_link(filer_id)
    type = filer_id[0].eql?('N') ? 'committee' : 'candidate'
    "#{URL}?FilerID=#{filer_id}&Type=#{type}"
  end

  def store
    @keeper.store("#{@scraper.storehouse}store/")
    @scraper.clear
  end
end
