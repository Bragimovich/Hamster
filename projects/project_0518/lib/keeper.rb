require_relative '../models/il_cckc_case_activities'
require_relative '../models/il_cckc_case_info'
require_relative '../models/il_cckc_case_judgment'
require_relative '../models/il_cckc_case_party'
require_relative '../models/il_cckc_case_runs'

class Keeper
  def initialize
    @run_object = RunId.new(IlCckcCaseRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_data(data_array, model)
    model.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end

  def update_touch_id(md5_hash_array)
    IlCckcCaseInfo.where(:md5_hash => md5_hash_array).update_all(:touch_run_id => run_id) unless md5_hash_array.empty?
  end

  def mark_deleted
    IlCckcCaseInfo.where.not(:touch_run_id => run_id).update_all(:deleted => 1)
  end

end
