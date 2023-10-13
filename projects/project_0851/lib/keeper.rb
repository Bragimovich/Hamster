require_relative '../models/ct_new_haven_runs'
require_relative '../models/ct_new_haven_arrests'
require_relative '../models/ct_new_haven_bonds'
require_relative '../models/ct_new_haven_charges'
require_relative '../models/ct_new_haven_court_hearings'
require_relative '../models/ct_new_haven_holding_facilities'
require_relative '../models/ct_new_haven_inmate_additional_info'
require_relative '../models/ct_new_haven_inmate_ids'
require_relative '../models/ct_new_haven_inmate_statuses'
require_relative '../models/ct_new_haven_inmates'
require_relative '../models/ct_new_haven_parole_booking_dates'

class Keeper
  def initialize
    @run_object = RunId.new(CtNewHavenRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_hash, table_name) 
    table_name.constantize.insert(data_hash)
  end

  def fetch_db_inserted_md5_hash_ids(table_name)
    table_name.constantize.pluck(:md5_hash, :id)
  end

  def update_touch_run_id(md5_array, table_name)
    table_name.constantize.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def delete_using_touch_id(table_name)
    table_name.constantize.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def finish_download
    current_run = CtNewHavenRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def download_status
    CtNewHavenRuns.pluck(:download_status).last
  end

  def finish
    @run_object.finish
  end

end
