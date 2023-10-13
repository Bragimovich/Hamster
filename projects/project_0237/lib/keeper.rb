require_relative '../models/iowa_voter_registrations'
require_relative '../models/iowa_voter_registrations_run'

class Keeper

  def initialize
    @run_object = RunId.new(IovaRun)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    IowaRegistrations.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end

end
