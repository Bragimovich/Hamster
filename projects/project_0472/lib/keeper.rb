require_relative '../models/mt_bar_montanabar_org'
require_relative '../models/mt_bar_montanabar_org_runs'

class Keeper

  def initialize
    @run_object = RunId.new(MtBarMontanabarOrgRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def update_touched_run_id(md5_array)
    MtBarMontanabarOrg.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id)
  end

  def deleted
    MtBarMontanabarOrg.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def save_record(data_array)
    MtBarMontanabarOrg.insert_all(data_array)
  end
  
  def finish
    @run_object.finish
  end
end
