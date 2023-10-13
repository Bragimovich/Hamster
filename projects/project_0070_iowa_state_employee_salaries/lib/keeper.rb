# frozen_string_literal: true

require_relative '../models/iowa_state_employee_salaries'
require_relative '../models/iowa_state_employee_salaries_runs'

class  Keeper < Hamster::Harvester
  def initialize
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id 
  end

  def store_salaries(data_arr)
    unless data_arr.nil?
      data_arr.each do |h|
        digest_update(IowaStateEmployeeSalaries, h)
      end
    end
  end

  def update_delete_status
    IowaStateEmployeeSalaries.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
  end

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end

  def finish
    @run_object.finish
  end

  def digest_update(object, h)
    source_url = "https://www.legis.iowa.gov/publications/fiscal/salaryBook"
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash), deleted: false)
  
    if digest.nil?
      hash.merge!(run_id: @run_id, touched_run_id: @run_id, created_by: 'Anton Tkachuk', data_source_url: source_url, state: 'Iowa', scrape_frequency: 'yearly', md5_hash: create_md5_hash(hash))
      object.store(hash)
    else
      digest.update(touched_run_id: @run_id)
    end
  end
end
