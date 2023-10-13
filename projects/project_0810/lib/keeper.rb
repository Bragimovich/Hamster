require_relative '../models/maine_runs'
require_relative '../models/maine_inmates'
require_relative '../models/maine_arrests'
require_relative '../models/maine_inmate_ids'
require_relative '../models/maine_charges'
require_relative '../models/maine_court_hearings'
require_relative '../models/maine_holding_facilities'
require_relative '../models/maine_mugshots'
require_relative '../models/maine_inmate_additional_info'
require_relative '../models/maine_inmate_statuses'
require_relative '../models/maine_inmate_aliases'

class Keeper

  def initialize
    @run_object = RunId.new(MaineRuns)
    @run_id = @run_object.run_id
  end
  
  attr_reader :run_id

  DB_MODELS = {
    'maine_inmates' => MaineInmates, 
    'maine_arrests' => MaineArrests, 
    'maine_inmate_ids' => MaineInmatesIds, 
    'maine_charges' => MaineCharges, 
    'maine_court_hearings' => MaineCourts, 
    'maine_holding_facilities' => MaineHoldings, 
    'maine_mugshots' => MaineMugshots, 
    'maine_inmate_additional_info' => MaineAdditional, 
    'maine_inmate_statuses' => MaineInmatesStatus, 
    'maine_inmate_aliases' => MaineAliases
  }

  def download_status
    MaineRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = MaineRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def finish
    @run_object.finish
  end

  def insert_for_foreign_key(hash, model)
    DB_MODELS[model].insert(hash) unless hash.nil?
    id = DB_MODELS[model].where(md5_hash: hash[:md5_hash]).pluck(:id)[0]
    DB_MODELS[model].where(md5_hash: hash[:md5_hash]).update_all(touched_run_id: run_id)
    id
  end

  def insert_data(data, model)
    data.is_a?(Array) ? DB_MODELS[model].insert_all(data) : DB_MODELS[model].insert(data) unless data.empty? || data.nil?
    data = [data].flatten
    md5_array = data.map {|e| e[:md5_hash]}
    DB_MODELS[model].where(md5_hash: md5_array).update_all(touched_run_id: run_id)
  end

  def marked_deleted
    DB_MODELS.values.each do |value|
      value.where.not(touched_run_id: run_id).update_all(deleted: 1)
    end
  end  
end
