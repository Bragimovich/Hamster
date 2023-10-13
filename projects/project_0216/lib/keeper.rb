require_relative '../models/cra_ratings_runs'
require_relative '../models/cra_ratings'

class Keeper
  def initialize
    @run_object = RunId.new(CraRatingsRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_hash)
    data_hash.count < 10000 ? CraRatings.insert_all(data_hash) : data_hash.each_slice(10000){|data| CraRatings.insert_all(data)}  
  end

  def fetch_db_inserted_md5_hash
    CraRatings.pluck(:md5_hash)
  end

  def finish
    @run_object.finish
  end
end
