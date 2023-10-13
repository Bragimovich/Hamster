require_relative '../models/ga_employee_compensation_runs'
require_relative '../models/ga_employee_compensation'


class Keeper

  def initialize
    @run_object = RunId.new(GaEmployeeCompensationRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(hash_array)
    hash_array.each_slice(5000) do |data|
      GaEmployeeCompensation.insert_all(data)
    end
  end

  def finish
    @run_object.finish
  end
end
