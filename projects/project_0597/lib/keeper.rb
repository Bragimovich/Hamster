require_relative '../models/ct_higher_education_salaries_runs'
require_relative '../models/ct_higher_education_salaries'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(CtHigherEducationSalariesRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array)
    CtHigherEducationSalaries.insert_all(data_array) unless data_array.empty?
  end

  def finish
    @run_object.finish
  end
end
