require_relative '../models/nm_bernalillo_arrests'
require_relative '../models/nm_bernalillo_bonds'
require_relative '../models/nm_bernalillo_charges'
require_relative '../models/nm_bernalillo_disciplinary_reports'
require_relative '../models/nm_bernalillo_inmate_ids_additional'
require_relative '../models/nm_bernalillo_inmate_ids'
require_relative '../models/nm_bernalillo_inmates'
require_relative '../models/nm_bernalillo_mugshots'
require_relative '../models/nm_bernalillo_court_hearings'
require_relative '../models/nm_bernalillo_runs'

class Keeper

  DB_MODELS = {
    "arrest" => NmBernalilloArrests,
    "bonds" => NmBernalilloBonds,
    "charges" => NmBernalilloCharges,
    "address" => NmBernalilloDisciplinaryReports,
    "inmate_ids_additional" => NmBernalilloInmateIdsAdditional,
    "inmates_ids" => NmBernalilloInmateIds,
    "inmates" => NmBernalilloInmates,
    "mugshot" => NmBernalilloMugshots,
    "court"   => NmBernalilloCourtHearings
  }


  def initialize
    @run_object = RunId.new(NmBernalilloRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_record(key, data_hash)
    data_hash.each do |data|
      DB_MODELS[key].insert(data)
    end
    update_touch_run_id(data_hash, key)
  end

  def insert_return_id(key, data_hash)
    DB_MODELS[key].insert(data_hash)
    update_touch_run_id(data_hash, key)
    DB_MODELS[key].find_by(md5_hash: data_hash[:md5_hash])[:id]
  end

  def fetch_charge_id(number, arrest_id)
    NmBernalilloCharges.where(number: number, arrest_id: arrest_id).pluck(:id).last
  end

  def update_touch_run_id(data_hash, key)
    data_hash = [data_hash].flatten
    md5_array = data_hash.map {|e| e[:md5_hash]}
    DB_MODELS[key].where(md5_hash: md5_array).update_all(touched_run_id: run_id)
  end

  def finish_download
    current_run = NmBernalilloRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def download_status
    NmBernalilloRuns.pluck(:download_status).last
  end

  def marked_deleted
    DB_MODELS.values.each do |value|
      value.where.not(touched_run_id: run_id).update_all(deleted: 1)
    end
  end

  def finish
    @run_object.finish
  end

end
