require_relative '../models/fda_runs'
require_relative '../models/fda_inspections_citations'
require_relative '../models/fda_inspections'

class Keeper

  def initialize
    @run_object = RunId.new(FdaRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  DB_MODELS = {
    'citations' => FdaInspectionsCitations,
    'inspections' => FdaInspections,
  }

  def save_records(data_array, key)
    DB_MODELS[key].insert_all(data_array) unless data_array.empty?
  end

  def update_touched_run_id(md5_array, key)
    DB_MODELS[key].where(md5_hash: md5_array).update_all(touched_run_id: run_id)
  end

  def mark_deleted
    DB_MODELS.keys.each{|key| DB_MODELS[key].where.not(touched_run_id: run_id).update_all(deleted: 1)}
  end

  def download_status
    FdaRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = FdaRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def finish
    @run_object.finish
  end
end
