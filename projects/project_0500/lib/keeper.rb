require_relative '../models/ar_court_arkansas_gov'
require_relative '../models/ar_court_arkansas_gov_runs'
class Keeper
  def initialize
    @run_object = RunId.new(ArCourtArkansasGovRuns)
    @run_id = @run_object.run_id
  end

  def delete_old_records
    ArCourtArkansasGov.where.not(touched_run_id: @run_id).each { |row| ArCourtArkansasGov.mark_deleted(row.id) }
  end

  def store(hash)
    hash = add_md5_hash(hash)
    check = ArCourtArkansasGov.where(data_source_url: hash['data_source_url'], deleted: false).as_json.first
    if check && check['md5_hash'] == hash['md5_hash']
      ArCourtArkansasGov.udpate_touched_run_id(check['id'],@run_id)
    elsif check
      ArCourtArkansasGov.mark_deleted(check['id'])
      ArCourtArkansasGov.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    else
      ArCourtArkansasGov.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
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