require_relative '../models/delaware_voter_registrations'
require_relative '../models/delaware_voter_registrations_run' 

class Keeper

  def initialize
    @run_object = RunId.new(DelawareVoterRegistrationsRun)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(voter_info_array)
    DelawareVoterRegistrations.insert_all(voter_info_array)
  end

  def finish
    @run_object.finish
  end
end
