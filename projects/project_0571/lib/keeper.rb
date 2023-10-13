# frozen_string_literal: true
require_relative '../models/mt_employee_salary_scrape'
require_relative '../models/mt_employee_salary_scrape_runs'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(MTEmployeeSalaryRuns)
    @run_id = @run_object.run_id
  end

  def fetch_md5(year)
    MTEmployeeSalary.where(year: "#{year}").pluck(:md5_hash)
  end

  def update_touched_run_id(update_array)
    MTEmployeeSalary.where(md5_hash: update_array).update_all(touched_run_id: run_id)
  end

  def mark_delete
    MTEmployeeSalary.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

  def download_status
    MTEmployeeSalaryRuns.pluck(:download_status).last
  end

  def finish_download
    current_run = MTEmployeeSalaryRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def insert_records(data_array)
    data_array.each_slice(5000){|data| MTEmployeeSalary.insert_all(data)} unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

end
