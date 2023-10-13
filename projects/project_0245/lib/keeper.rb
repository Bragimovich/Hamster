require_relative '../models/alaska_voter'
require_relative '../models/alaska_voter_runs'

class Keeper
  def initialize
    @run_object = RunId.new(AlaskaVoterRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def already_inserted_md5
    AlaskaVoter.pluck(:md5_hash)
  end

  def db_inserted_links
    AlaskaVoter.pluck(:link).uniq
  end

  def insert_records(data_array)
    AlaskaVoter.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end
end
