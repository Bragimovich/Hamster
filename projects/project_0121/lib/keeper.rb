# frozen_string_literal: true

require_relative '../models/freddie_mac'
require_relative '../models/runs'

class  Keeper < Hamster::Harvester
  def initialize
    super
    @run_object = RunId.new(FreddieMacRun)
    @run_id = @run_object.run_id 
  end

  def store_release(data_hash)
    hash = FreddieMac.flail { |key| [key, data_hash[key]] }
    find_dig = FreddieMac.find_by(md5_hash: create_md5_hash(hash), deleted: false)
    if find_dig.nil?
      hash.merge!({data_source_url: "https://freddiemac.gcs-web.com/", run_id: @run_id, touched_run_id: @run_id,  md5_hash: create_md5_hash(hash)})
      FreddieMac.store(hash) 
    else
      find_dig.update(touched_run_id: @run_id)
    end
  end

  def update_delete_status
    FreddieMac.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end

  def finish
    @run_object.finish
  end
end
