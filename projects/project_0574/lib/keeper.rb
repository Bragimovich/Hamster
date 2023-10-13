require_relative '../models/ky_public_employee_salaries'
require_relative '../models/ky_public_employee_salaries_runs'

class Keeper

  def initialize
    @run_object = RunId.new(KyPublicRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    KyPublic.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end

end

