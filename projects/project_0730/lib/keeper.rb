require_relative '../models/ca_higher_ed_salaries_runs'
require_relative '../models/ca_higher_ed_salaries'
class Keeper
  def initialize
    @run_object = RunId.new(CaHigerEdSalariesRuns)
    @run_id = @run_object.run_id
  end

  def ad_ids(hash)
    if !hash.nil?
      hash['run_id'] = @run_id
      hash['touched_run_id'] = @run_id
    end  
    hash
  end

  def update_touch_run_id(md5_array)
    update_touch_id(CaHigerEdSalaries, md5_array.flatten)
  end

  def store_ca_ed_salaries(list_of_hashes)
   list_of_hashes = list_of_hashes.map{ |hash| ad_ids(hash) }
   CaHigerEdSalaries.insert_all(list_of_hashes)
  end

  def update_touch_id(model, array)
    array.each_slice(5000) { |data| model.where(:md5_hash => data).update_all(:touched_run_id => @run_id) }
  end

  def finish
    @run_object.finish
  end
end