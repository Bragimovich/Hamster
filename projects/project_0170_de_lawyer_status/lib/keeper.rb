require_relative '../models/delaware'
require_relative '../models/delaware_runs'

class Keeper

  def initialize
    @run_object = RunId.new(DelawareRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    DelawareRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = DelawareRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def save_record(hash_array)
    Delaware.insert_all(hash_array) unless hash_array.empty?
    md5_hashes = hash_array.map { |e| e[:md5_hash] }
    Delaware.where(:md5_hash => md5_hashes).update_all(:touched_run_id => run_id) unless md5_hashes.empty?
  end

  def mark_deleted
    Delaware.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def finish
    @run_object.finish
  end
end
