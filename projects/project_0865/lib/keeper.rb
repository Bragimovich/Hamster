require_relative '../models/co_csu_salaries_runs'
require_relative '../models/co_csu_salaries'

class Keeper

  def initialize
    @run_object = RunId.new(CoCsuSalariesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    CoCsuSalariesRuns.pluck(:download_status).last
  end

  def insert_data(array)
    CoCsuSalaries.insert_all(array)
  end

  def update_touched_run_id(md5_array)
    CoCsuSalaries.where(md5_hash: md5_array).update_all(touched_run_id: run_id) unless ((md5_array.nil?) || (md5_array.empty?))  
  end

  def mark_deleted
    CoCsuSalaries.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

  def finish
    @run_object.finish
  end

  def finish_download
    current_run = CoCsuSalariesRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

end
