# frozen_string_literal: true
require_relative '../models/nj'
require_relative '../models/nj_runs'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NjRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array)
    data_array.each_slice(10000){|data| NjState.insert_all(data)} unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

end
