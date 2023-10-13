require_relative '../models/tx_runs'
require_relative '../models/tx_info'
require_relative '../models/tx_activity'
require_relative '../models/tx_party'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(TxRuns)
    @run_id = @run_object.run_id
  end

  def last_inserted_record
    TxInfo.pluck(:case_filed_date).max
  end

  def update_touch_run_id
    TxInfo.update_all(:touched_run_id => run_id)
    TxActivity.update_all(:touched_run_id => run_id)
    TxParty.update_all(:touched_run_id => run_id)
  end

  def insert_records(data_array)
    TxInfo.insert_all(data_array)
  end

  def insert_activity(data_array)
    TxActivity.insert_all(data_array)
  end

  def insert_party(data_array)
   TxParty.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end

end
