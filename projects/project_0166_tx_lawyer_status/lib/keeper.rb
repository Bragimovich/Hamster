require_relative '../models/texas'
require_relative '../models/texas_runs'
require_relative '../models/usa_administrative_division_states'

class Keeper

  def initialize
    @run_object = RunId.new(TexasRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    TexasRuns.pluck(:download_status).last
  end

  def save_record(data_array)
    Texas.insert_all(data_array)
  end

  def del_using_touch_id
    Texas.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def update_touch_run_id(md5_array)
    Texas.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def usa_administrative_division_states
    USAStates.all().map { |row| row[:short_name] }
  end

  def fetch_db_inserted_md5_hash
    Texas.pluck(:md5_hash)
  end

  def fetch_db_inserted_links
    Texas.where(run_id: run_id).pluck(:data_source_url)
  end

  def finish
    @run_object.finish
  end

  def finish_download
    current_run = TexasRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

end
