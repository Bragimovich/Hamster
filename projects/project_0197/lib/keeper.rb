# frozen_string_literal: true

require_relative '../models/us_dept_has'
require_relative '../models/us_dept_has_run'

class  Keeper < Hamster::Harvester
  def initialize
    super
    @run_object = RunId.new(UsDeptHasRun)
    @run_id = @run_object.run_id 
  end

  def store_release(data_hash)
    hash = UsDeptHas.flail { |key| [key, data_hash[key]] }
    hash.merge!({creator: "US Department of HCA"})
    find_dig = UsDeptHas.find_by(md5_hash: create_md5_hash(hash), deleted: false)
    if find_dig.nil?
      hash.merge!({run_id: @run_id, touched_run_id: @run_id,  md5_hash: create_md5_hash(hash)})
      UsDeptHas.store(hash) 
    else
      find_dig.update(touched_run_id: @run_id)
    end
  end

  def update_delete_status
    UsDeptHas.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
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
