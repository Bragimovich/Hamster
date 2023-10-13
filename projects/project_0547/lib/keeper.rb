# frozen_string_literal: true

require_relative '../models/ut_public_employee_salaries'
require_relative '../models/ut_public_employee_salaries_runs'

class Keeper
  def initialize
    @run_object = RunId.new(UtahSalaryRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    data_array.each_slice(5000).each do |record_array|
      UtahSalary.insert_all(record_array)
    end
  end

  def finish
    @run_object.finish
  end
end
