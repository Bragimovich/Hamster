# frozen_string_literal: true
require_relative '../models/ok_bar_runs'
require_relative '../models/ok_bar'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(OkBarRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array)
    OkBar.insert_all(data_array) unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

  def update_touch_id(md5_array)
    OkBar.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id)
  end

  def mark_delete
    OkBar.where("touched_run_id is NULL or touched_run_id != #{run_id}").update_all(:deleted => 1)
  end

  def get_inserted_md5
    OkBar.pluck(:md5_hash)
  end

end
