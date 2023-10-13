require_relative '../models/db'
require_relative '../models/db_for_dev'
require_relative '../models/runs'

class Keeper
  def initialize
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id
  end

  def delete_old_records
    Db.where.not(touched_run_id: @run_id).each { |row| Db.mark_deleted(row.id) }
    DbForDev.where.not(touched_run_id: @run_id).each { |row| DbForDev.mark_deleted(row.id) }
  end

  def store(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    # remove nil key value pairs in hash
    hash = hash.reject{|k,v| k.nil?}
    check = Db.where(md5_hash: hash[:md5_hash]).as_json.first
    if check
      Db.udpate_touched_run_id(check['id'], @run_id)
    else
      Db.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def store_for_devs(hash)
    hash = HashWithIndifferentAccess.new(hash)
    hash = add_md5_hash(hash)
    # remove nil key value pairs in hash
    hash = hash.reject{|k,v| k.nil?}
    check = DbForDev.where(md5_hash: hash[:md5_hash]).as_json.first
    if check
      DbForDev.udpate_touched_run_id(check['id'],@run_id)
    else
      DbForDev.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
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