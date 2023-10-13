require_relative '../models/naveda_public_employee'
require_relative '../models/naveda_public_employee_runs'

class Keeper
  def initialize
    @run_object = RunId.new(NavedaPublicRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    NavedaPublic.insert_all(data_array)
  end

  def fetch_db_inserted_md5_hash
    NavedaPublic.pluck(:md5_hash)
  end

  def finish
    @run_object.finish
  end

end
