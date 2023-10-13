require_relative '../models/missouri_arrests'
require_relative '../models/missouri_charges'
require_relative '../models/missouri_court_hearings'
require_relative '../models/missouri_holding_facilities_addresses'
require_relative '../models/missouri_holding_facilities'
require_relative '../models/missouri_inmate_additional_info'
require_relative '../models/missouri_inmate_addresses'
require_relative '../models/missouri_inmate_aliases'
require_relative '../models/missouri_inmate_ids'
require_relative '../models/missouri_inmates_runs'
require_relative '../models/missouri_inmates'
require_relative '../models/missouri_mugshots'

class Keeper

  def initialize
    @run_object = RunId.new(MissouriInmatesRuns)
    @run_id = @run_object.run_id
  end

  DB_MODELS = {'missour_inmates' => MissouriInmates, 'missouri_arrests' => MissouriArrests, 'missouri_charges' => MissouriCharges,'missouri_court_hearings' => MissouriCourtHearings, 'missouri_mugshots' => MissouriMugshots, 'missouri_inmate_additional_info' => MissouriInmateAdditionalInfo, 'missouri_inmate_addresses' => MissouriInmateAddresses, 'missouri_holding_facilities_addresses' => MissouriHoldingFacilitiesAddresses, 'missouri_holding_facilities' => MissouriHoldingFacilities, 'missouri_inmate_aliases' => MissouriInmateAliases, 'missouri_inmate_ids' => MissouriInmateIds }

  attr_reader :run_id

  def fetch_doc_ids
    MissouriInmateIds.pluck(:number).uniq
  end

  def insert_for_foreign_key(hash, model)
    DB_MODELS[model].insert(hash)
    id = DB_MODELS[model].where(:md5_hash => hash[:md5_hash]).pluck(:id)[0]
    DB_MODELS[model].where(:md5_hash => hash[:md5_hash]).update_all(:touched_run_id => run_id)
    id
  end

  def insert_data(data, model)
    data.is_a?(Array) ? DB_MODELS[model].insert_all(data) : DB_MODELS[model].insert(data)
    data = [data].flatten
    md5_array = data.map {|e| e[:md5_hash]}
    DB_MODELS[model].where(:md5_hash => md5_array).update_all(:touched_run_id => run_id)
  end

  def marked_deleted
    DB_MODELS.values.each do |value|
      value.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    end
  end

  def finish
    @run_object.finish
  end

end
