# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}.freeze
URL = 'https://www.cdc.gov/poxvirus/mpox/response'
CDC_PAGE = "#{URL}/2022/us-map.html"
# CSV_LINK = "#{URL}/modules/MX-response-case-count-US.json"
USA_CSV_LINK = "https://www.cdc.gov/poxvirus/mpox/data/USmap_counts/exported_files/usmap_counts.csv"
WORLD_CSV_LINK = "https://www.cdc.gov/wcms/vizdata/poxvirus/monkeypox/data/MPX-Cases-Deaths-by-Country.csv"
DAY = 86_400

class MonkeypoxCDC < Hamster::Harvester
  def initialize
    super
    @scraper = Scraper.new
    @keeper = Keeper.new
  end

  def download
    @pdf_data = @scraper.scrape
    @usa_csv = @scraper.download_csv(USA_CSV_LINK)
  end

  def parse
    @cases_data = Parser.new.parse_csv(@scraper.csv_path)
  end

  def store
    @keeper.store_pdf(@pdf_data)
    @keeper.store_cases(@cases_data)

    aws_links = @scraper.put_all_to_aws
    @keeper.update_aws_links(aws_links)
    @scraper.clear(aws_links)
  end
end
