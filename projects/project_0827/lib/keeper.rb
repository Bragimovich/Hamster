# require model files here
require_relative '../models/co_denver_runs'
require_relative '../models/co_denver_a'
require_relative '../models/co_denver_inmate_ids'
require_relative '../models/co_denver_inmates'
require_relative '../models/co_denver_add_info'

class Keeper
  def initialize
    super
    @run_object = RunId.new(CoDenverRuns)
    @run_id = @run_object.run_id
  end

  def ad_ids(hash)
    if !hash.nil?
      hash['run_id'] = @run_id
      hash['touched_run_id'] = @run_id
    end  
    hash
  end

  def store_inmates(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    CoDenverInmates.insert_all(list_of_hashes)
  end 
  
  def store_arrestsupdate(list_of_hashes)
    list_of_hashes = list_of_hashes.map { |hash| ad_ids(hash) }
    list_of_hashes.each do |hash|
      CoDenverA.where(inmate_id: hash[:inmate_id]).update_all(hash.except(:inmate_id))
    end
  end
  
  def store_inmates_addinfo(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    CoDenverAddInfo.insert_all(list_of_hashes)
  end

  def store_arrests(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    CoDenverA.insert_all(list_of_hashes)
  end
  
  def store_inmateids(list_of_hashes)
    list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
    CoDenverInmateIds.insert_all(list_of_hashes)
  end

  def finish
    @run_object.finish
  end
end