# frozen_string_literal: true
require_relative '../models/nh_public_employee_salaries'
require_relative '../models/nh_public_employee_salaries_runs'

class Keeper
  def initialize
    @run_object = RunId.new(NhPublicEmployeeSalariesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id
  
  def insert_file(data_array)
    begin
      batch_size = 1000
      data_array.each_slice(batch_size) do |batch|
          NhPublicEmployeeSalaries.insert_all(batch)
      end
    rescue Exception => e
      Hamster.logger.debug e.full_message
    end
  end

  def finish
    @run_object.finish
  end
end
