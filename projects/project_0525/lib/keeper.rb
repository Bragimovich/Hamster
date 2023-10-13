require_relative '../models/ms_bar_msbar_org_runs'
require_relative '../models/ms_bar_msbar_org'

class Keeper
  
  def initialize
    @run_object = RunId.new(MsBarMsbarOrgRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def save_records(data_array)
    MsBarMsbarOrg.insert_all(data_array) unless data_array.empty?
  end

  def fetch_already_inserted_md5
    MsBarMsbarOrg.pluck(:md5_hash)
  end

  def update_touch_run_id(run_id_update_array)
    MsBarMsbarOrg.where(:md5_hash => run_id_update_array).update_all(:touched_run_id => run_id)
  end

  def mark_deleted
    MsBarMsbarOrg.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end
  
  def finish
    @run_object.finish
  end
end
