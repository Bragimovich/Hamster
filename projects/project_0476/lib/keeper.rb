require_relative '../models/indiana'
require_relative '../models/michigan'
require_relative '../models/georgia'
require_relative '../models/illinois'
require_relative '../models/nebraska'
require_relative '../models/inbar_runs'

class Keeper

  DB_MODELS = {"georgia" => Georgia, "michigan" => Michigan, "indiana" => Indiana,'nebraska' => Nebraska,'illinois' => Illinois}

  RUNS_COLUMNS = {"georgia" => :georgia_status, "michigan" => :michigan_status, "indiana" => :indiana_status,'nebraska' => :nebraska_status,'illinois' => :illinois_status}

  def initialize
    @run_object = RunId.new(InbarRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def mark_delete(key)
    DB_MODELS[key].where("touched_run_id is NULL or touched_run_id != #{run_id}").update_all(:deleted => 1)
  end

  def update_download_status(key)
    InbarRuns.where(:id => run_id).update(RUNS_COLUMNS[key] => 1)
  end

  def get_download_status(key)
    InbarRuns.where(:id => run_id).pluck(RUNS_COLUMNS[key]).first
  end

  def update_touch_id(key,md5_array)
    DB_MODELS[key].where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def save_record(key,data_array)
    DB_MODELS[key].insert_all(data_array) unless data_array.empty?
  end

  def get_inserted_md5(key)
    DB_MODELS[key].pluck(:md5_hash)
  end

  def finish
    @run_object.finish
  end

end
