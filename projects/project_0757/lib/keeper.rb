require_relative '../models/fdic_bank_runs'
require_relative '../models/fdic_bank_failures'
class Keeper

  def initialize
    @run_object = RunId.new(FdicBankRuns)
    @run_id = @run_object.run_id
  end

  def save_data_to_fdic_bank_failures(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    FdicBankFailures.insert(data)
  end

  def existed_data(md5_hash)
    FdicBankFailures.where(md5_hash:md5_hash).first
  end

  def finish
    @run_object.finish
  end

end
