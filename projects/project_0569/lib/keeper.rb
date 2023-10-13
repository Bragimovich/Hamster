require_relative '../models/mn_public_employee_salaries_roaster'
require_relative '../models/mn_public_employee_salaries_runs'
require_relative '../models/mn_public_employee_salaries'

class Keeper

  DB_MODELS = {"earnings" => MnPublicEmployeeSalaries, "hr" => MnPublicEmployeeSalariesRoaster}

  def initialize
    @run_object = RunId.new(MnPublicEmployeeSalariesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(key, hash_array)
    hash_array.each_slice(5000) do |data|
      DB_MODELS[key].insert_all(data)
    end
  end

  def finish
    @run_object.finish
  end
end
