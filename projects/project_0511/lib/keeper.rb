# frozen_string_literal: true

require_relative '../models/il_la_salle_arrestees'
require_relative '../models/il_la_salle_arrests'
require_relative '../models/il_la_salle_bonds'
require_relative '../models/il_la_salle_charges'
require_relative '../models/il_la_salle_mugshots'
require_relative '../models/runs'

class  Keeper < Hamster::Harvester
  attr_writer :data_arr

  def initialize
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id 
  end

  def data_arrestees
    @data_arr.each do |row|
      digest_update(IlLaSalleArrestees, row)
    end
  end

  def data_arrests
    @data_arr.each do |row|
      arrestee = find_md5_hash(IlLaSalleArrestees, row)
      row.merge!({ arrestee_id: arrestee.id})
      digest_update(IlLaSalleArrests, row)
    end
  end

  def data_charges
    @data_arr.each do |row|
      arrest = find_md5_hash(IlLaSalleArrests, row)
      row[:charge_hash].each do |charge|
        hash_charge = {
          arrest_id: arrest.id,
          description: charge[0],
          data_source_url: row[:data_source_url]
        }
        digest_update(IlLaSalleCharges, hash_charge)
      end
    end
  end

  def data_bonds
    @data_arr.each do |row|
      arrest = find_md5_hash(IlLaSalleArrests, row)
      row[:charge_hash].each do |charge|
        hash_charge = {
          arrest_id: arrest.id,
          description: charge[0],
          data_source_url: row[:data_source_url]
        }
        charges = find_md5_hash(IlLaSalleCharges, hash_charge)
        bonds_hash = {
          arrest_id: arrest.id,
          charge_id: charges.id,
          bond_category: "Total Bond",
          bond_amount: charge[1],
          data_source_url: row[:data_source_url]
        }
        digest_update(IlLaSalleBonds, bonds_hash)
      end
    end
  end

  def data_mugshots
    @data_arr.each do |row|
      arrestee = find_md5_hash(IlLaSalleArrestees, row)
      row.merge!({ arrestee_id: arrestee.id})
      digest_update(IlLaSalleMugshots, row)
    end
  end

  def find_md5_hash(object, row)
    hash = object.flail { |key| [key, row[key]] }
    object.find_by(md5_hash: create_md5_hash(hash))
  end

  def digest_update(object, h)
    source_url =  "https://isoms.lasallecounty.org/portal/Jail"
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash), deleted: false)
  
    if digest.nil?
      hash.merge!({run_id: @run_id, touched_run_id: @run_id, data_source_url: source_url,  md5_hash: create_md5_hash(hash)})
      object.store(hash)
    else
      digest.update(touched_run_id: @run_id)
    end
  end

  def update_delete_status
    IlLaSalleArrestees.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    IlLaSalleArrests.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    IlLaSalleCharges.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    IlLaSalleBonds.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
    IlLaSalleMugshots.where(deleted: 0).where.not(touched_run_id: @run_id).update(deleted: 1)
  end

  def finish
    @run_object.finish
  end

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end
end
