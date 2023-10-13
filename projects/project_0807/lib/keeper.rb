require_relative '../models/mo_jackson_inmates'
require_relative '../models/mo_jackson_charges'
require_relative '../models/mo_jackson_arrests'
require_relative '../models/mo_jackson_inmate_ids'
require_relative '../models/mo_jackson_mugshots'
require_relative '../models/mo_jackson_inmate_ids_additional'
require_relative '../models/mo_jackson_inmate_aliases'
require_relative '../models/mo_jackson_runs'

class Keeper
  DB_MODELS = {
    "inmate"          => MoJacksonInmates,
    "inmate_id"       => MoJacksonInmateID,
    "arrests"         => MoJacksonArrests,
    "charges"         => MoJacksonCharges,
    "mugshots"        => MoJacksonMugshots,
    "aliases"         => MoJacksonAliases,
    "addiotional_ids" => MoJacksonIdsAdditional
  }

  def initialize
    @run_object = RunId.new(MoJacksonRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id


  def insert_record(key, data_hash)
    DB_MODELS[key].insert(data_hash)
    DB_MODELS[key].where(md5_hash: data_hash[:md5_hash]).pluck(:id)[0]
  end

  def insert_multiple(key, array)
    DB_MODELS[key].insert_all(array)
  end

  def finish_download
    current_run = MoJacksonRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def download_status
    MoJacksonRuns.pluck(:download_status).last
  end

  def update_touch_run_id(key, md5_array)
    DB_MODELS[key].where(md5_hash: md5_array).update_all(touched_run_id: run_id) unless md5_array.empty?
  end

  def delete_using_touch_id(key)
    DB_MODELS[key].where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

  def finish
    @run_object.finish
  end
end
