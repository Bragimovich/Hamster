require_relative '../models/colorado_runs'
require_relative '../models/colorado'

class Keeper
  def initialize
    @run_object = RunId.new(ColoradoRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def get_deceased_records
    Colorado.where("registration_status =  'Deceased'").pluck(:bar_number)
  end

  def mark_deleted
    ids_extract = Colorado.where(:deleted => 0).group(:bar_number).having("count(*) > 1").pluck("bar_number, GROUP_CONCAT(id)")
    all_old_ids = []
    ids_extract.each do |value|
      ids = value[-1].split(",").map(&:to_i)
      ids.delete ids.max
      all_old_ids << ids
    end
    all_old_ids = all_old_ids.flatten
    Colorado.where(:id => all_old_ids).update_all(:deleted => 1)
  end

  def already_fetched_md5
    Colorado.pluck(:md5_hash)
  end

  def save_records(data_array)
    Colorado.insert_all(data_array)
  end
  
  def finish
    @run_object.finish
  end
end
