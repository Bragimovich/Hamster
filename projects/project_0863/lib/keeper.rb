require_relative '../models/wa_pierce_inmate_runs'
require_relative '../models/wa_pierce_arrests'
require_relative '../models/wa_pierce_charges'
require_relative '../models/wa_pierce_court_hearings'
require_relative '../models/wa_pierce_holding_facilities'
require_relative '../models/wa_pierce_inmates'
require_relative '../models/wa_pierce_bonds'

class Keeper

  DB_MODELS = {"inmates" => Inmate, "arrests" => InmateArrests, "charges" => InmateCharges, "hearings" => InmateHearings, "facilities" => InmateFacilities, "bonds" => InmateBonds}

  def initialize
    @run_object = RunId.new(InmateRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def already_inserted_records
    InmateArrests.where(touched_run_id: run_id).pluck(:booking_number)
  end

  def mark_download_status(id)
    InmateRuns.where(id: run_id).update(download_status: "True")
  end

  def download_status(id)
    InmateRuns.where(id: run_id).pluck(:download_status)
  end

  def insert_for_foreign_key(hash, model)
    DB_MODELS[model].insert(hash)
    id = DB_MODELS[model].where(md5_hash: hash[:md5_hash]).pluck(:id)[0]
    DB_MODELS[model].where(md5_hash: hash[:md5_hash]).update_all(touched_run_id: run_id)
    id
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
