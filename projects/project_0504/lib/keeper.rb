# frozen_string_literal: true

require_relative '../models/il_tazewell__arrestees'
require_relative '../models/il_tazewell__arrestee_ids'
require_relative '../models/il_tazewell__arrests'
require_relative '../models/il_tazewell__charges'
require_relative '../models/runs'

class  Keeper < Hamster::Harvester
  attr_writer :data_arr

  def initialize
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id 
  end

  def data_arrestees
    @data_arr.each do |row|
      digest_update(IlTazewellArrestees, row)
    end
  end

  def arrestee_ids
    @data_arr.each do |row|
      arrestee = find_md5_hash(IlTazewellArrestees, row)
      row.merge!({ arrestee_id: arrestee.id, number: row[:detainee_id], type: "DetaineeId"})
      digest_update(IlTazewellArresteeIds, row)
    end
  end

  def data_arrests
    @data_arr.each do |row|
      arrestee = find_md5_hash(IlTazewellArrestees, row)
      row.merge!({ arrestee_id: arrestee.id})
      digest_update(IlTazewellArrests, row)
    end
  end

  def data_charges
    @data_arr.each do |row|
      arrestee = find_md5_hash(IlTazewellArrestees, row)
      row.delete(:number)
      arrest = find_md5_hash(IlTazewellArrests, row)
      row.merge!({arrest_id: arrest.id, number: arrestee.id  })
      digest_update(IlTazewellCharges, row)
    end
  end

  def update_delete_status
    IlTazewellArrestees.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    IlTazewellArresteeIds.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    IlTazewellArrests.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    IlTazewellCharges.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
  end

  def finish
    @run_object.finish
  end

  def digest_update(object, h)
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash), deleted: false)
    if digest.nil?
      hash.merge!({run_id: @run_id, touched_run_id: @run_id, md5_hash: create_md5_hash(hash)})
      object.store(hash)
    else
      digest.update(touched_run_id: @run_id)
    end
  end

  def find_md5_hash(object, row)
    hash = object.flail { |key| [key, row[key]] }
    object.find_by(md5_hash: create_md5_hash(hash))
  end

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end
end
