require_relative '../models/ri_higher_ed_salaries'
require_relative '../models/ri_higher_ed_salaries_runs'

class Keeper

  def initialize
    @run_object = RunId.new(RiHigherEdSalariesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_data(data_array)
    md5_hash_array = data_array.map { |e| e[:md5_hash] }
    data_array.each_slice(5000) { |data| RiHigherEdSalaries.insert_all(data) }
    md5_hash_array.each_slice(5000) { |data| RiHigherEdSalaries.where(:md5_hash => data).update_all(:touched_run_id => run_id) }
  end

  def mark_records_delete
    RiHigherEdSalaries.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def finish
    @run_object.finish
  end

end
