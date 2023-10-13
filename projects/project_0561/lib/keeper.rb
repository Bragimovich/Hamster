require_relative '../models/index'

class Keeper
  def initialize
    @run_object = RunId.new(FarmSubsidiesRun)
    @run_id = @run_object.run_id
  end

  def store(hash)
    store_subsidy(hash)
  end

  def store_subsidy(hash)
    exists = FarmSubsidy.where(md5_hash: get_md5_hash(hash))&.first
    if exists
      FarmSubsidy.update(exists['id'], {touched_run_id: @run_id})
    else
      hash = add_md5_hash(hash)
      FarmSubsidy.insert(hash)
    end
  end

  def finish
    @run_object.finish
  end
  
  private

  def add_md5_hash(hash)
    hash['md5_hash'] = get_md5_hash(hash)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    hash
  end 

  def get_md5_hash(hash)
    md5_hash = Digest::MD5.hexdigest(hash.to_s)
    md5_hash
  end 

end