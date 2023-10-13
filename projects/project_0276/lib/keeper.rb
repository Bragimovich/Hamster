require_relative '../models/us_senate'
require_relative '../models/us_senate_runs'

class Keeper
  def initialize
    @run_object = RunId.new(UsSenateRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    UsSenateRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = UsSenateRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def mark_deleted
    UsSenate.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def insert_record(data_array)
    UsSenate.insert_all(data_array)
    all_md5_hashes = data_array.map{|e| e[:md5_hash]}
    UsSenate.where(md5_hash: all_md5_hashes).update_all(touched_run_id: run_id)
  end

  def fetch_db_inserted_links
    UsSenate.pluck(:data_source_url)
  end

  def finish
    @run_object.finish
  end

end
