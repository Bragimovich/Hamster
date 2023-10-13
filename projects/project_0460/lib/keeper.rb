require_relative '../models/oh_supremecourt_attorneys'
require_relative '../models/oh_supremecourt_attorneys_runs'

class Keeper

  def initialize
    @run_object = RunId.new(OhSupremecourtAttorneysRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    OhSupremecourtAttorneysRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = OhSupremecourtAttorneysRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def save_record(data_array)
    OhSupremecourtAttorneys.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end

  def update_touched_run_id(md5_array)
    OhSupremecourtAttorneys.where(md5_hash: md5_array).update_all(touched_run_id: run_id) unless ((md5_array.nil?) || (md5_array.empty?))
  end

  def mark_deleted
    OhSupremecourtAttorneys.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end
end
