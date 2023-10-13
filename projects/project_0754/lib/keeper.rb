require_relative '../models/cei_data'
require_relative '../models/cei_data_rating'
require_relative '../models/cei_runs'

class Keeper
  def initialize
    @run_object = RunId.new(CeiRuns)
    @run_id = @run_object.run_id
  end

  def get_cei_id(md5_hash)
    check = CeiData.where(md5_hash: md5_hash).select(:id).first
    if check then check.id end
  end

  def save_data_to_cei_data(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    CeiData.insert(data)
  end

  def save_data_to_cei_data_rating(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    CeiDataRating.insert(data)
  end

  def finish
    @run_object.finish
  end

end
