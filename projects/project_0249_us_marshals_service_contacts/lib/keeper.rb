require_relative '../models/us_dept_msc'
require_relative '../models/us_dept_msc_runs'

class Keeper

  def initialize
    super
    @run_object = RunId.new(UsDeptMscRuns)
    @run_id = @run_object.run_id 
  end

  attr_reader :run_id
  
  def save_record(data_hash)
    UsDeptMsc.insert(data_hash)
  end

  def fetch_db_inserted_links
    UsDeptMsc.pluck(:link)
  end

  def finish
    @run_object.finish
  end
end
