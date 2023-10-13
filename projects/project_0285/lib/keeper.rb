require_relative '../models/university_of_pittsburgh_directory'
require_relative '../models/university_of_pitts_burgh_runs'

class Keeper

  def initialize
    @run_object = RunId.new(UniversityOfPittsburghDirectoryRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def download_status
    UniversityOfPittsburghDirectoryRuns.pluck(:download_status).last
  end

  def insert_records(data_array)
    UniversityOfPittsburghDirectory.insert_all(data_array)
  end

  def update_touch_run_id(md5_hash_array)
    UniversityOfPittsburghDirectory.where(md5_hash: md5_hash_array).update_all(touched_run_id: run_id) unless md5_hash_array.empty?
  end

  def fetch_search_params
    UniversityOfPittsburghDirectory.where(run_id: run_id).pluck(:search_params).uniq
  end

  def delete_using_touch_id
    UniversityOfPittsburghDirectory.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

  def finish_download
    current_run = UniversityOfPittsburghDirectoryRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def finish
    @run_object.finish
  end

end
