# frozen_string_literal: true
require_relative '../models/sc_higher_ed_salaries_runs'
require_relative '../models/sc_higher_ed_salaries'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(SalariesRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array)
    EdSalaries.insert_all(data_array) unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

  def update_touched_run_id(md5_array)
    EdSalaries.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id)
  end

  def mark_delete
    EdSalaries.where("touched_run_id is NULL or touched_run_id != #{run_id}").update_all(:deleted => 1)
  end

end
