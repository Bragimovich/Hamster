# frozen_string_literal: true

require_relative '../models/vt_employee_salaries'
require_relative '../models/vt_employee_salaries_run'

class Keeper
  
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(VtEmployeeSalariesRun)
    @run_id = @run_object.run_id
  end

  def store(data)
    md5_hash = MD5Hash.new(columns: [:name,:job_title,:department,:job_type,:salary, :salary_type,:data_source_url])
    data[:md5_hash] = md5_hash.generate(data)
    data.merge!(run_id: run_id,touched_run_id: run_id)
    insert_model(VtEmployeeSalaries, data)
  end

  def finish
    @run_object.finish
  end

  def insert_model(model, hash)
    existing = model.find_by(md5_hash: hash[:md5_hash])
    # replace empty values with nil
    hash.each { |k, v| hash[k] = nil if v.kind_of?(String) && v.empty? }
    unless existing.nil?
      existing.update(touched_run_id: hash[:run_id],deleted: 0) 
    end
    model.insert(hash) if existing.nil?
  end

end
