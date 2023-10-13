require_relative '../models/voter_registration'
require_relative '../models/voter_registration_runs'

class Keeper

  def initialize
    @run_object = RunId.new(VoterRegsRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data)
    VoterRegs.insert_all(data)
  end

  def finish
    @run_object.finish
  end

end
