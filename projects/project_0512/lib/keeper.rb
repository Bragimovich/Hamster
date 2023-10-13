require_relative '../models/db'
require_relative '../models/runs'

class Keeper
  def initialize
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id
  end

  def store(hash)
    hash = HashWithIndifferentAccess.new(hash)
    hash = add_md5_hash(hash)
    check = Db.where(data_source_url: hash['data_source_url'], deleted: false).as_json.first
    if check && check['md5_hash'] == hash['md5_hash']
      Db.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      Db.mark_deleted(check['id'])
      Db.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      Db.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end
  
  def finish
    @run_object.finish
  end
end