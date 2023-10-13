# frozen_string_literal: true

require_relative '../models/gu_bar_guambar_org'
require_relative '../models/runs'

class  Keeper < Hamster::Harvester
  def initialize
    super
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id 
  end

  def store_data(hash)
    digest = GuBarGuambarOrg.find_by(md5_hash: hash[:digest], deleted: false)
    if digest.nil?
      hash.merge!({run_id: @run_id, touched_run_id: @run_id })
      GuBarGuambarOrg.store(hash)
    else
      digest.update(touched_run_id: @run_id)
    end
  end

  def update_delete_status
    GuBarGuambarOrg.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def finish
    @run_object.finish
  end
end
