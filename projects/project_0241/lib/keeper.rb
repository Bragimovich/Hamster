require_relative '../models/tx_employee_salary'
require_relative '../models/tx_employee_salary_runs'

class Keeper

  def initialize
    @run_object = RunId.new(TxEmpSalaryRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    TxEmpSalary.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end

end
