# require model files here
require_relative '../models/ma_worcester_inmates_runs'
require_relative '../models/ma_worcester_inmates'
require_relative '../models/ma_worcester_inmate_ids'
require_relative '../models/ma_worcester_holding_facilities'

class Keeper
  attr_reader :run_id

  def initialize
    super
    @run_object = RunId.new(MaWorcesterInmatesRuns)
    @run_id = @run_object.run_id
  end

  def store_inmate(hash)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    MaWorcesterInmates.insert(hash)
  end

  def store_inmate_ids(hash)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    MaWorcesterInmateIds.insert(hash)
  end

  def store_holding_fac(hash)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    MaWorcesterHoldingFacilities.insert(hash)
  end

  def finish
    @run_object.finish
  end
end
