require_relative '../models/tn_public_employee_salary_runs'
require_relative '../models/tn_public_employee_salary'

class Keeper
  def initialize
    @run_object = RunId.new(PublicEmployeeSalaryRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(data_hash)
    data_hash.each_slice(5000){|data_array| PublicEmployeeSalary.insert_all(data_array)}
  end

  def deleted(processed_md5_offenders)
    processed_md5_offenders.each_slice(5000){|delete_slice| PublicEmployeeSalary.where(:md5_hash => delete_slice).update_all(:is_deleted => 1)}
  end

  def fetch_db_inserted_md5_hash
    PublicEmployeeSalary.pluck(:md5_hash)
  end

  def finish
    @run_object.finish
  end

end
