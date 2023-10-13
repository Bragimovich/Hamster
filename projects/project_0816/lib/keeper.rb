require_relative '../models/minnesota_arrests_additional'
require_relative '../models/minnesota_arrests'
require_relative '../models/minnesota_charges'
require_relative '../models/minnesota_court_hearings'
require_relative '../models/minnesota_inmate_additional_info'
require_relative '../models/minnesota_inmate_ids'
require_relative '../models/minnesota_inmate_statuses'
require_relative '../models/minnesota_inmates'
require_relative '../models/minnesota_mugshots'
require_relative '../models/minnesota_runs'
require_relative '../models/minnesota_holding_facilities'

class Keeper

  def initialize
    @run_object = RunId.new(MinnesotaRuns)
    @run_id = @run_object.run_id
  end

  DB_MODELS = {
    'minnesota_arrests_additional' => MinnesotaArrestsAdditional, 
    'minnesota_arrests' => MinnesotaArrests, 
    'minnesota_charges' => MinnesotaCharges,
    'minnesota_court_hearings' => MinnesotaCourtHearings,
    'minnesota_holding_facilities' => MinnesotaHoldingFacilities,
    'minnesota_inmate_additional_info' => MinnesotaInmateAdditionalInfo,
    'minnesota_inmate_ids' => MinnesotaInmateIds,
    'minnesota_inmate_statuses' => MinnesotaInmateStatuses,
    'minnesota_inmates' => MinnesotaInmates,
    'minnesota_mugshots' => MinnesotaMugshots
  }

  attr_reader :run_id

  def insert_for_foreign_key(hash, model, md5_hash)
    DB_MODELS[model].insert(hash)
    id = DB_MODELS[model].where(md5_hash: md5_hash).pluck(:id)[0]
    DB_MODELS[model].where(md5_hash: md5_hash).update_all(touched_run_id: run_id)
    id
  end

  def insert_data(data, model, md5_hash)
    data.is_a?(Array) ? DB_MODELS[model].insert_all(data) : DB_MODELS[model].insert(data)
    data = [data].flatten
    DB_MODELS[model].where(md5_hash: md5_hash).update_all(touched_run_id: run_id) 
  end

  def download_status
    MinnesotaRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = MinnesotaRuns.find_by(id: run_id)
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
