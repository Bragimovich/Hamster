require_relative '../models/arizona'
require_relative '../models/arizona_runs'
class Keeper

  def initialize
    @run_object = RunId.new(ArizonaRuns)
    @run_id = @run_object.run_id
  end
  attr_reader :run_id

  def save_record(data_hash)
    Arizona.insert(data_hash)
  end

  def mark_deleted
    Arizona.where.not(:touched_run_id => @run_id).update_all(:deleted => 1)
  end

  def update_touched_runId(md5_hash_array)
    Arizona.where(:md5_hash => md5_hash_array).update_all(:touched_run_id => @run_id) unless md5_hash_array.empty?
  end

  def already_fetched
    Arizona.where(:deleted => 0).pluck(:data_source_url).uniq
  end

  def already_inserted_md5_hashes
    Arizona.pluck(:md5_hash)
  end

  def finish
    @run_object.finish
  end
end
