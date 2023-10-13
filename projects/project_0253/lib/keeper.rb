require_relative '../models/michigan_public_employee_salary'
require_relative '../models/michigan_public_employee_salary_runs' 

class Keeper

  def initialize
    @run_object = RunId.new(MichiganPublicEmployeeSalaryRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_array)
    MichiganPublicEmployeeSalary.insert_all(data_array)
  end

  def download_status
    MichiganPublicEmployeeSalaryRuns.pluck(:download_status).last
  end

  def update_touch_run_id(md5_array)
    MichiganPublicEmployeeSalary.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def delete_using_touch_id
    MichiganPublicEmployeeSalary.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def finish_download
    current_run = MichiganPublicEmployeeSalaryRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def finish
    @run_object.finish
  end
end
