require_relative '../models/mn_employee_runs'
require_relative '../models/mn_employee'
require_relative '../models/mn_public_employee_salaries'

class Keeper
  def initialize
    @run_object = RunId.new(EmployeeRuns)
    @run_id = @run_object.run_id
  end
  
  attr_reader :run_id

  def save_record(data_array, name)
    name = name.constantize
    data_array.count < 5000 ? name.insert_all(data_array) : data_array.each_slice(5000){|data_array| name.insert_all(data_array)} unless data_array.empty?
  end
  
  def finish
    @run_object.finish
  end
end
