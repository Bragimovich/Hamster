require_relative '../models/ma_dhcd'
require_relative '../models/ma_dhcd_run'

class Keeper

  def initialize
    super
    @run_object = RunId.new(MaDhcdRun)
    @run_id = @run_object.run_id 
  end

  attr_reader :run_id

  def save_record(data_array)
    MaDhcd.insert_all(data_array)
  end

  def fetch_db_inserted_links
    MaDhcd.pluck(:link)
  end
  
  def finish
    @run_object.finish
  end
end
