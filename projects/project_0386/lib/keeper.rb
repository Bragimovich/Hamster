# frozen_string_literal: true

require_relative '../models/or_osbar'
require_relative '../models/runs'

class  Keeper < Hamster::Harvester
  def initialize
    super
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id 
  end

  def store_data(data_hash)
    hash = OrOsbar.flail { |key| [key, data_hash[key]] }
    find_dig = OrOsbar.find_by(md5_hash: create_md5_hash(hash))
    if find_dig.nil?
      hash.merge!({ md5_hash: create_md5_hash(hash), run_id: @run_id, touched_run_id: @run_id})
      OrOsbar.store(hash) 
    else
      find_dig.update(touched_run_id: @run_id)
    end
  end

  def update_delete_status
    OrOsbar.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
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
