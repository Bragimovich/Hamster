# frozen_string_literal: true
require_relative '../models/ks_cc_employee_salaries'
require_relative '../models/ks_k12_employee_salaries'
require_relative '../models/ks_k12_employee_salaries_runs'

class Keeper

  MODELS = {'KsCcSal' => KsCcEmployeeSalary, 'KsSal' => KsEmployeeSalary}

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(KsRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array,key)
    data_array.each_slice(5000){ |data| MODELS[key].insert_all(data) } unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

  def update_touch_run_id(md5_array,key)
    md5_array.each_slice(5000){|data| MODELS[key].where(md5_hash: data).update_all(touched_run_id: run_id)} unless md5_array.empty?
  end

  def mark_delete(key)
    MODELS[key].where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

end
