# frozen_string_literal: true

require_relative '../models/ks_public_employee_salaries'
require_relative '../models/ks_public_employee_salaries_runs'

class Keeper
  def initialize
    @run_object = RunId.new(KansasSalaryRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    KansasSalary.insert_all(data_array)
  end

  def finish
    @run_object.finish
  end
end
