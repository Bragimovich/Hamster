# frozen_string_literal: true

require_relative '../models/ohio_state_employee_salaries'
require_relative '../models/runs'

class  Keeper < Hamster::Harvester
  attr_writer :year
  def initialize
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id 
    @main_arr = []
  end

  def enrollment(row)
    hash = {
      name: row["Name"],
      job_title: row["Job Title"],
      agency: row["Agency"],
      max_hourly_rate: row["Max. Hourly Rate"].gsub("$","").gsub(",","").gsub(" ","").to_f,
      amount: row["Amount"].gsub("$","").gsub(",","").gsub(" ","").to_f,
      year: @year
    }

    digest = OhioStateEmployeeSalaries.find_by(md5_hash: create_md5_hash(hash), deleted: false)

    if digest.nil?
      hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: "https://checkbook.ohio.gov/Salaries/State.aspx", md5_hash: create_md5_hash(hash))
      @main_arr  << hash
    else
      digest.update(touched_run_id: @run_id)
    end
  end

  def store_enrollment
    unless @main_arr.empty?
      OhioStateEmployeeSalaries.insert_all(@main_arr)
      @main_arr.clear
    end
  end

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end

  def update_delete_status
    OhioStateEmployeeSalaries.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
  end
  
  def finish
    @run_object.finish
  end
end
