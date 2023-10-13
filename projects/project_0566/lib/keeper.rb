# frozen_string_literal: true
require_relative '../models/ne_courts'
require_relative '../models/ne_court_runs'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NeRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array)
    NeCourt.insert_all(data_array) unless data_array.empty?
  end

  def update_touch_id(md5_array)
    NeCourt.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id)
  end

  def mark_delete
    NeCourt.where("touched_run_id is NULL or touched_run_id != #{run_id}").update_all(:deleted => 1)
  end

  def finish
    @run_object.finish
  end

end
