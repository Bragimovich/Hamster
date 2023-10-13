require_relative '../models/raw_ca__contra_costa__runs'
require_relative '../models/raw_ca__contra_costa_county_inmates__arrests_charges'
require_relative '../models/raw_ca__contra_costa_county_inmates__arrests'
class Keeper
  def initialize
    @run_object = RunId.new(RawCaContraCostaRuns)
    @run_id = @run_object.run_id
  end

  def ad_ids(hash)
    if !hash.nil?
      hash['run_id'] = @run_id
      hash['touched_run_id'] = @run_id
    end  
    hash
  end

  def store_arrests_info(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    RawCaContraCostaCountyInmatesArrests.insert_all(list_of_hashes)
  end
  
  def get_name_id
    name_id_hashes = RawCaContraCostaCountyInmatesArrests.pluck(:name,:id)
  end

  def store_arrests_chargedesc(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    RawCaContraCostaCountyInmatesArrestsCharges.insert_all(list_of_hashes)
  end
  
  def finish
    @run_object.finish
  end
end    