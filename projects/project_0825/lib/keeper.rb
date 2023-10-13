require_relative '../models/nj_essex_inmates'
require_relative '../models/nj_essex_inmates_runs'
require_relative '../models/nj_essex_inmate_additional_info'
require_relative '../models/nj_essex_mugshots'
require_relative '../models/nj_essex_holding_facilities'
require_relative '../models/nj_essex_holding_facilities_addresses'
require_relative '../models/nj_essex_bonds'
require_relative '../models/nj_essex_charges'
require_relative '../models/nj_essex_arrests'
require_relative '../models/nj_essex_inmate_ids'
require_relative '../models/nj_essex_inmate_aliases'

class Keeper
  attr_reader :run_id

  def initialize
    super
    @run_object = RunId.new(NjEssexInmatesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_data(hash, model)
    model = model.constantize
    model.insert(hash)
    model.where(:md5_hash => [hash[:md5_hash]]).update_all(:touched_run_id => run_id)
    model.where(:md5_hash => hash[:md5_hash]).pluck(:id)[0]
  end

  def store(data_array, model)
    model = model.constantize
    data_array.each_slice(5000) { |data| model.insert_all(data) }
    md5_hash_array = data_array.map { |e| e[:md5_hash] }
    md5_hash_array.each_slice(5000) { |data| model.where(:md5_hash => data).update_all(:touched_run_id => run_id) }
  end

  def mark_delete
    models = [NjEssexArrests, NjEssexBonds, NjEssexCharges, NjEssexHoldingFacilitiesAddresses, NjEssexHoldingFacilities, NjEssexInmateAdditionalInfo, NjEssexInmateAliases, NjEssexInmateIds, NjEssexInmates, NjEssexMugshots]
    models.each do |model|
      model.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    end
  end

  def finish
    @run_object.finish
  end
end
