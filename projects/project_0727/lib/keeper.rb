require_relative '../models/ga_employee_runs'
require_relative '../models/ga_employee_salaries'

class Keeper
  def initialize
    @run_object = RunId.new(GaEmployeeRuns)
    @run_id = @run_object.run_id
  end
  
  def store(list_of_hashes)
    list_of_hashes = list_of_hashes.map{|hash| add_md5_hash(hash)}
    splits = list_of_hashes.each_slice(10000).to_a
    splits.each do |split|
      GaEmployeeSalaries.insert_all(split)
    end
  end

  def finish
    @run_object.finish
  end
  
  private
  
  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    hash
  end
end
