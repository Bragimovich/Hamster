require_relative '../models/california_voter_registrations_runs'
require_relative '../models/california_voter_registrations'

class Keeper
  def initialize
    @run_object = RunId.new(CaliforniaVoterRegistrationRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_hash)
    CaliforniaVoterRegistration.insert_all(data_hash)
  end

  def finish
    @run_object.finish
  end
end
