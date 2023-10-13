require_relative '../models/iowa_professional_licensing_scrape'
require_relative '../models/iowa_professional_licensing_scrape_runs'
require_relative '../models/iowa_cities'

class Keeper
  def initialize
    @run_object = RunId.new(IowaProfRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def delete_duplicates
    ids_extract = IowaProf.where(:deleted => 0).group(:number).having("count(*) > 1").pluck("number, GROUP_CONCAT(id)")
    all_old_ids = []
    ids_extract.each do |value|
      ids = value[-1].split(",").map(&:to_i)
      ids.delete get_max(ids)
      all_old_ids << ids
    end
    all_old_ids = all_old_ids.flatten
    IowaProf.where(:id => all_old_ids).update_all(:deleted => 1)
  end

  def get_max(value)
    value.max
  end

  def fetch_cities
    IowaCities.where(state: "IA").pluck(:primary_city).uniq.sort
  end

  def insert_records(data_array)
    IowaProf.insert_all(data_array) unless data_array.empty?
  end

  def db_inserted_links
    IowaProf.where(touched_run_id: run_id, deleted: 0).pluck(:data_source_url)
  end

  def fetch_db_inserted_md5_hash
    IowaProf.pluck(:md5_hash)
  end

  def update_missing_records
    rec = IowaProf.where(deleted: 1).where.not(data_source_url: IowaProf.select(:data_source_url).where(deleted: 0)).pluck(:id)
    IowaProf.where(id: rec).update_all(deleted: 0)
  end

  def mark_download_status(id)
    IowaProfRuns.where(id: run_id).update(download_status: "True")
  end

  def update_touched_run_id(array)
    IowaProf.where(md5_hash: array).update_all(touched_run_id: run_id, deleted: 0)
  end

  def download_status(id)
    IowaProfRuns.where(id: run_id).pluck(:download_status)
  end

  def mark_deleted
    IowaProf.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

  def finish
    @run_object.finish
  end
end
