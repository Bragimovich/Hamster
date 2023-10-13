require_relative '../models/colorado_voter_registrations_runs'
require_relative '../models/colorado_voter_registrations'

class Keeper
  def initialize
    @run_object = RunId.new(ColoradoVotersRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def save_records(data_array)
    ColoradoVoters.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end
end
