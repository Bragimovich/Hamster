require_relative '../models/pennsylvania_voter_registrations'
require_relative '../models/pennsylvania_voter_registrations_run'

class Keeper

  def initialize
    @run_object = RunId.new(PennsylvaniaRun)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    PennsylvaniaRegistrations.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end
end
