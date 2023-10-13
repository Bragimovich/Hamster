require_relative '../models/alabama_state'
require_relative '../models/alabama_state_runs'

class Keeper

  def initialize
    @run_object = RunId.new(AlabamaRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(arrayy)
    AlabamaState.insert(arrayy)
  end

  attr_reader :run_id
  
  def update_touch_run_id(md5_array)
    AlabamaState.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def delete_using_touch_id
    AlabamaState.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def download_status
    AlabamaRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = AlabamaRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def finish
    run_id.finish
  end

end
