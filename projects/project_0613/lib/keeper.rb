require_relative '../models/mi_higher_education_salaries'
require_relative '../models/mi_higher_education_salaries_run'

class Keeper

  def initialize
    @run_object = RunId.new(MIHigherEducationSalariesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def mi_salaries(data_array)
    MIHigherEducationSalaries.insert_all(data_array)
  end

  def mark_deleted
    MIHigherEducationSalaries.where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def update_touched_runId(md5_hash_array)
    MIHigherEducationSalaries.where(md5_hash: md5_hash_array).update_all(touched_run_id: @run_id) unless md5_hash_array.empty?
  end

  def download_finished
    MIHigherEducationSalariesRuns.find_by(id: run_id).update(download_status: 'finish')
  end

  def download_status
    MIHigherEducationSalariesRuns.pluck(:download_status).last
  end

  def finish
    @run_object.finish
  end
end
