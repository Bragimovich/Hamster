require_relative '../models/az_public_runs'
require_relative '../models/az_public'

class Keeper

  def initialize
    @run_object = RunId.new(AzPublicRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    AzPublicRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = AzPublicRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def save_records(data_array)
    AzPublic.insert_all(data_array) unless data_array.nil? || data_array.empty?
  end

  def fetch_already_inserted_md5
    AzPublic.pluck(:md5_hash)
  end

  def update_touch_run_id(run_id_update_array)
    AzPublic.where(:md5_hash => run_id_update_array).update_all(:touched_run_id => run_id)
  end

  def mark_deleted
    AzPublic.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def finish
    @run_object.finish
  end
end
