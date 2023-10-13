require_relative '../models/arizona_voter_registrations_runs'
require_relative '../models/arizona_voter_registrations'

class Keeper
  def initialize
    @run_object = RunId.new(ArizonaVoterRegistrationRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_hash)
    ArizonaVoterRegistration.insert_all(data_hash)
  end

  def fetch_db_inserted_links
    ArizonaVoterRegistration.pluck(:link).uniq
  end

  def finish
    @run_object.finish
  end
end
