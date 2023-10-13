require_relative '../models/ok_k12_employee_salaries'
require_relative '../models/ok_k12_employee_salaries_runs'

class Keeper

  def initialize
    @parser = Parser.new
    @run_object = RunId.new(OkK12EmployeeSalariesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_data(data_array)
    data_array.each_slice(5000) { |data| OkK12EmployeeSalaries.insert_all(data) }
    md5_hash_array = data_array.map { |e| e[:md5_hash] }
    md5_hash_array.each_slice(5000) { |data| OkK12EmployeeSalaries.where(:md5_hash => data).update_all(:touched_run_id => run_id) }
  end

  def finish
    @run_object.finish
  end

  def mark_delete
    OkK12EmployeeSalaries.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end
end
