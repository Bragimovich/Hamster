require_relative '../models/harris_county_tx_delinquent_tax_sale_propertise_runs'
require_relative '../models/harris_county_tx_delinquent_tax_sale_property'

class Keeper
  def initialize
    @run_object = RunId.new(HarrisCountyTxDelinquentTaxSalePropertiesRuns)
    @run_id = @run_object.run_id
  end
  
  attr_reader :run_id
  
  def finish
    @run_object.finish
  end
end
