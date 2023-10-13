require_relative '../models/north_carolina'
require_relative '../models/north_carolina_runs'

class Keeper

  def initialize
    @run_object = RunId.new(NorthCarolinaRun)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def mark_deleted
    ids_extract = NorthCarolina.where(:deleted => 0).group(:bar_number).having("count(*) > 1").pluck("bar_number, GROUP_CONCAT(id)")
    all_old_ids = ids_extract.map{|e| e.last.split(',').map(&:to_i)}.each{|e| e.delete(e.max)}.flatten
    NorthCarolina.where(:id => all_old_ids).update_all(:deleted => 1)
  end

  def already_inserted_md5
    NorthCarolina.pluck(:md5_hash)
  end

  def already_inserted_links
    NorthCarolina.where(run_id: run_id).pluck(:link)
  end

  def insert_records(lawyers_info_array)
    NorthCarolina.insert_all(lawyers_info_array)
  end

  def finish
    @run_object.finish
  end

end
