require_relative '../models/us_doj_ojp_runs'
require_relative '../models/us_doj_ojp'

class UsDojOjpKeeper
  def initialize
    super
    @run_object = RunId.new(UsDoOjpRuns)
    @run_id = @run_object.run_id 
  end

  def fetch_db_inserted_links
    UsDojOjp.pluck(:link)
  end
  
  def save_record(data_hash)
    UsDojOjp.insert(data_hash)
  end

  def finish
    @run_object.finish
  end

  attr_reader :run_id
    
end
