require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize()
    super
    @keeper = Keeper.new
    @response
  end

  def download
    scraper = Scraper.new

    url = 'https://www.hctax.net/Property/listings/taxsalelisting'
    @response = scraper.load_page(url)
  end

  def store
    return Hamster.report(
          to: 'dmitiry.suschinsky',
          message: '#33 Harris County Tx Delinquent Tax Sale Property - table empty'
        ) if @response.class == NilClass

    parser = Parser.new
    records = parser.get_records(@response)
    parser.parse_data(records)

    @keeper.finish
  end

end
