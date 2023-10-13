require_relative '../models/massachusetts_public_school_info'
require_relative '../models/massachusetts_public_school_district_info'
require_relative '../models/massachusetts_public_runs'

class Keeper

  def initialize
    super
    @run_object = RunId.new(MassachusettsPublicRuns)
    @run_id = @run_object.run_id 
  end

  DB_MODELS = {'school' => MassachusettsPublicSchoolInfo, 'district' => MassachusettsPublicSchoolDistrictInfo}

  attr_reader :run_id
  
  def save_record(data_array, key)
    DB_MODELS[key].insert_all(data_array) unless data_array.empty?
  end

  def update_touch_run_id(db_md5, key)
    DB_MODELS[key].where(:md5_hash => db_md5).update_all(:touched_run_id => run_id)
  end

  def mark_deleted(key)
    DB_MODELS[key].where("touched_run_id is NULL or touched_run_id != '#{run_id}'").update_all(:deleted => 1)
  end

  def fetch_db_md5(key)
    DB_MODELS[key].pluck(:md5_hash)
  end

  def finish
    @run_object.finish
  end
end
