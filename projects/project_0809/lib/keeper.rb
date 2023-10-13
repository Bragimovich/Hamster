require_relative '../models/il_dupage_court_addresses'
require_relative '../models/il_dupage_hold_info'
require_relative '../models/il_dupage_arrests'
require_relative '../models/il_dupage_bonds'
require_relative '../models/il_dupage_charges'
require_relative '../models/il_dupage_court_hearings'
require_relative '../models/il_dupage_inmate_additional_info'
require_relative '../models/il_dupage_inmate_ids'
require_relative '../models/il_dupage_inmates'
require_relative '../models/il_dupage_mugshots'
require_relative '../models/il_dupage_runs'

class Keeper

  def initialize
    @run_object = RunId.new(IlDupageRuns)
    @run_id = @run_object.run_id
  end

  DB_MODELS = {
    'court_addresses' => IlDupageCourtAddresses, 
    'il_hold_info' => IlDupageHoldInfo,
    'il_dupage_arrests' => IlDupageArrests, 
    'il_dupage_bonds' => IlDupageBonds,
    'il_dupage_charges' => IlDupageCharges, 
    'il_dupage_court_hearings' => IlDupageCourtHearings, 
    'il_dupage_inmate_additional_info' => IlDupageAdditionalInfo, 
    'il_dupage_inmate_ids' => IlDupageInmateIds, 
    'il_dupage_inmates' => IlDupageInmates, 
    'il_dupage_mugshots' => IlDupageMugshots,  
  }

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(IlDupageRuns)
    @run_id = @run_object.run_id
  end

  def insert_for_foreign_key(hash, model, md5_hash)
    DB_MODELS[model].insert(hash)
    id = DB_MODELS[model].where(md5_hash: md5_hash).pluck(:id)[0]
    DB_MODELS[model].where(md5_hash: md5_hash).update_all(touched_run_id: run_id)
    id
  end

  def fetch_case_number_charges(value)
    IlDupageCharges.where(docket_number: value).pluck(:id).last
  end

  def insert_data(data, model, md5_hash)
    data.is_a?(Array) ? DB_MODELS[model].insert_all(data) : DB_MODELS[model].insert(data)
    data = [data].flatten
    DB_MODELS[model].where(md5_hash: md5_hash).update_all(touched_run_id: run_id) 
  end

  def download_status
    IlDupageRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = IlDupageRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def mark_delete
    DB_MODELS.values.each do |value|
      value.where.not(touched_run_id: run_id).update_all(deleted: 1)
    end
  end

  def finish
    @run_object.finish
  end

end
