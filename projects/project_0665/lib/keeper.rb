require_relative '../models/ct_state_employee_payroll_data_runs'
require_relative '../models/ct_state_employee_payroll_data'

class Keeper
  def initialize
    @run_object = RunId.new(EmployeePayrollDataRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def finish_download
    current_run = EmployeePayrollDataRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def save_records(records_array)
    records_array.each_slice(5000) do |record|
      CtStateEmployeePayroll.insert_all(record)
    end
  end

  def delete_using_touch_id
    CtStateEmployeePayroll.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end


  def update_touch_run_id(md5_array)
    CtStateEmployeePayroll.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def download_status
    EmployeePayrollDataRuns.pluck(:download_status).last
  end

  def finish
    @run_object.finish
  end
end
