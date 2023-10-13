# frozen_string_literal: true
require_relative '../models/ny_public_salaries'
require_relative '../models/ny_public_salaries_runs'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NyRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array)
    data_array.each_slice(5000){ |data| NyPublicSalary.insert_all(data) } unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

  def update_touch_run_id(md5_array)
    md5_array.each_slice(5000){|data| NyPublicSalary.where(md5_hash: data).update_all(touched_run_id: run_id)} unless md5_array.empty?
  end

  def mark_delete
    NyPublicSalary.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

end
