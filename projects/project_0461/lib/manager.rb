# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}
PAGE = "https://www.epdata.es/casos-confirmados-viruela-mono-paises/dca8048d-5728-470b-8b96-f66f2ec98998"
RAW_PAGE = 'https://www.epdata.es/representacion/getrepresentacion/dca8048d-5728-470b-8b96-f66f2ec98998'
DAY = 86400
ES_MONTH = %w(enero abril agosto diciembre)
EN_MONTH = %w(january april august december)

class EpData < Hamster::Harvester
  def download
    @pdf_data = Scraper.new.scrape
  end

  def parse
    @cases_data = Parser.new.parse(Scraper.new.get_source(RAW_PAGE))
  end

  def store
    Keeper.new.store_pdf(@pdf_data)
    Keeper.new.store_cases(@cases_data)
  end
end
