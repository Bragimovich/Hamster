require_relative '../models/fdic'
require_relative '../models/fdic_runs'

class Keeper
  def initialize
    @run_object = RunId.new(FdicRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def fetch_db_inserted_links
    Fdic.pluck(:link)
  end

  def save_record(data_hash)
    Fdic.insert(data_hash)
  end

  def finish
    @run_object.finish
  end
end
