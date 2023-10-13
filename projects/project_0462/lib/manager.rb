# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

HEADERS = {
  accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language: 'en-US,en;q=0.5',
  connection: 'keep-alive',
  upgrade_insecure_requests: '1'
}.freeze

CYCLE = 2022
URL = 'https://www.opensecrets.org'
PAGE = "#{URL}/elections-overview/top-organizations?cycle=#{CYCLE}"
API_PAGE = "#{URL}/api/?apikey=1a011ef5bb8194a4297d09dc42d2eaf7&method=getOrgs&output=json&org="
NO_LINK = '< NO-LINK >'
ORGS_CSV = "Orgs#{CYCLE}.csv"
PARTY_CSV = "Source_by_Party_#{CYCLE}.csv"
FUNDS_CSV = "Source_by_Funds_#{CYCLE}.csv"
AFFIL_CSV = "Affiliates_#{CYCLE}.csv"
RECIP_CSV = "Recipients_#{CYCLE}.csv"

class OpenSecretsManager < Hamster::Harvester
  def initialize
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @path = "#{@scraper.storehouse}store/"
  end

  def parse_orgs_with_api
    ('aaa'..'zzz').each do |orgname|
      url = API_PAGE + orgname
      source = @scraper.get_source(url)
      next if source.status != 200
      @scraper.store_to_csv(@parser.get_orgs(source), ORGS_CSV)
    end
  end

  def parse
    parse_orgs_with_api # running approximately 40 hours
    @keeper.csv_to_db("#{@path}#{ORGS_CSV}", 'opensecrets__organizations')

    @orgs_in_db = Keeper.new.get_orgs
    @orgs_in_db.each do |org|  # running approximately 80 hours
      source = @scraper.get_source(org[:link])
      @scraper.store_to_csv(@parser.get_by_party(source, org), PARTY_CSV)
      @scraper.store_to_csv(@parser.get_by_funds(source, org), FUNDS_CSV)
      @scraper.store_to_csv(@parser.get_affiliates(source, org), AFFIL_CSV)

      org[:link] = "#{URL}/orgs/recipients?id=#{org_id}&toprecipscycle=#{CYCLE}"
      source = @scraper.get_source(org[:link])
      @scraper.store_to_csv(@parser.get_recipients(source, org), RECIP_CSV)
    end
  end

  def store
    @keeper.csv_to_db("#{@path}#{ORGS_CSV}", 'opensecrets__organizations')
    @keeper.csv_to_db("#{@path}#{PARTY_CSV}", 'opensecrets__contributions_by_party_of_recipient')
    @keeper.csv_to_db("#{@path}#{FUNDS_CSV}", 'opensecrets__contributions_by_source_of_funds')
    @keeper.csv_to_db("#{@path}#{AFFIL_CSV}", 'opensecrets__affiliates')
    @keeper.csv_to_db("#{@path}#{RECIP_CSV}", 'opensecrets__recipients')
  end
end
