require_relative '../models/db_states'
require_relative '../models/us_dept_oig_dol'
require_relative '../models/us_dept_oig_dol_runs'

class Keeper
  def initialize
    @run_object = RunId.new(UsDeptRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def fetch_states
    DbStates.all.map{|e| [e[:state], e[:short_state]]}.uniq
  end

  def insert_record(data_hash)
    UsDept.insert(data_hash)
  end

  def fetch_db_inserted_links
    UsDept.pluck(:link)
  end

  def finish
    @run_object.finish
  end

end
