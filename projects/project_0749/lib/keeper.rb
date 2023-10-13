# frozen_string_literal: true

require_relative '../models/models'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NvRawRuns)
    @run_id = @run_object.run_id
  end

  def finish
    @run_object.finish
  end

  def insert_records(data_array, model)
    data_array.each_slice(8000){|data| model.insert_all(data)} unless data_array.empty?
  end

  def update_touch_run_id(md5_array, model)
    md5_array.each_slice(8000){|data| model.where(md5_hash: data).update_all(touched_run_id: run_id)} unless md5_array.empty?
  end

  def mark_delete(model)
    model.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

end
