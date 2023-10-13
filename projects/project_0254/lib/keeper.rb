require_relative '../models/ fl_public_employee_salaries_runs'
require_relative '../models/ fl_public_employee_salaries' 

class Keeper

  def initialize
    @run_object = RunId.new(FlPublicEmployeeSalariesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    data_array.each_slice(5000) do |data_slice|
      FlPublicEmployeeSalaries.insert_all(data_slice)
    end
  end

  def finish
    @run_object.finish
  end
end
