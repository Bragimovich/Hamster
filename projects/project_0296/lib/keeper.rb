require_relative '../models/idaho_voter_registrations'
require_relative '../models/idaho_voter_registrations_runs'

class Keeper
  def initialize
    @run_object = RunId.new(IdahoRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def save_record(data_array)
    IdahoVoter.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end
end
