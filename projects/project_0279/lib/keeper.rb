require_relative '../models/nevada_criminal_offenders_run'
require_relative '../models/nevada_criminal_offenders'
require_relative '../models/nevada_criminal_offenders_offenses'

class Keeper

  def initialize
    @run_object = RunId.new(NevadaCriminalOffendersRun)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  DB_MODELS = {
    "offenders" => NevadaCriminalOffenders,
    "offenses" => NevadaCriminalOffendersOffenses
  }

  def download_status
    NevadaCriminalOffendersRun.pluck(:download_status).last
  end

  def finish_download
    current_run = NevadaCriminalOffendersRun.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def update_touched_run_id(processed_md5, key)
    DB_MODELS[key].where(md5_hash: processed_md5).update_all(touched_run_id: run_id)
  end

  def save_records(hash_array, key)
    unless hash_array.empty?
      hash_array.each_slice(5000){|data| DB_MODELS[key].insert_all(data)}
    end
  end

  def deleted(key)
    DB_MODELS[key].where.not(touched_run_id: run_id).update_all(is_deleted: 1)
  end

  def finish
    @run_object.finish
  end
end
