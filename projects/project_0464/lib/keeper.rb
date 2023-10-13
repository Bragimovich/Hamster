require_relative '../models/aid_by_state'
require_relative '../models/aid_by_archive'
require_relative '../models/fafsa_college_student_runs'

class Keeper
  
  def initialize
    @run_object = RunId.new(FafsaCollegeStudenRuns)
    @run_id = @run_object.run_id
  end

  def store_state(list_of_hashes)
    splits = list_of_hashes.each_slice(10000).to_a
    splits.each do |split|
      list_of_hashes = split.map{|hash| add_md5_hash(hash) }
      AidByState.insert_all(list_of_hashes)
    end
  end
  
  def store_archive(list_of_hashes)
    splits = list_of_hashes.each_slice(10000).to_a
    splits.each do |split|
      list_of_hashes = split.map{|hash| add_md5_hash(hash) }
      AidByArchive.insert_all(split)
    end
  end
  
  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    hash
  end

  def finish
    @run_object.finish
  end
end