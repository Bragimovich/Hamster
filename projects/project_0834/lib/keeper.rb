# frozen_string_literal: true

require_relative '../models/runs'
require_relative '../models/tx_bexar_inmates'
require_relative '../models/tx_bexar_inmate_ids'
require_relative '../models/tx_bexar_arrests'
require_relative '../models/tx_bexar_charges'
require_relative '../models/tx_bexar_bonds'
require_relative '../models/tx_bexar_arrests_additional'


class Keeper < Hamster::Harvester
  attr_writer :data_hash, :url

  def initialize
  super
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id
  end

  def store_inmate
    @inmate = digest_update(TxBexarInmates, @data_hash)
    @data_hash.merge!(inmate_id: @inmate.id)
  end

  def store_inmate_ids
    digest_update(TxBexartxInmateIds, @data_hash)
  end

  def store_arrests
    @arrest = digest_update(TxBexarArrests, @data_hash)
  end

  def store_arrests_additional
    @data_hash.each do |key, value|
      if key == (:intake_time) || key == (:magistration_time) || key == (:disposition) || key == (:magistrate_release_date) || key == (:comments)
        unless value.nil?
          hash = {
              key: key,
              value: value,
              arrest_id: @arrest.id
            }
          hash.merge!({run_id: @run_id, touched_run_id: @run_id, md5_hash: create_md5_hash(hash)})
          digest_update(TxBexarArrestsAdditional, hash)
        end
      end
    end
  end

  def store_charges
    @data_hash[:data_table].each do |value|
      value.merge!(arrest_id: @arrest.id)
      charge = digest_update(TxBexarCharges, value)
      value.merge!(charge_id: charge.id)
    end
  end

  def store_bonds
    @data_hash[:data_table].each do |value|
      digest_update(TxBexarBonds, value)
    end
  end

  def digest_update(object, h)
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash))

    if digest.nil?
      hash.merge!({run_id: @run_id, touched_run_id: @run_id, data_source_url: @url, md5_hash: create_md5_hash(hash)})
      object.store(hash)
    else
      digest.update(touched_run_id: @run_id, deleted: false) 
      digest
    end
  end

  def finish
    @run_object.finish
  end

  def create_md5_hash(hash)
    str = ""
    hash.each do |field|
      unless field.include?(:data_source_url) || field.include?(:run_id) || field.include?(:touched_run_id) || field.include?(:md5_hash) || field.include?(:age)
        str += field.to_s
      end
    end
    digest = Digest::MD5.new.hexdigest(str)
  end

  def update_delete_status
    models = [TxBexarInmates, TxBexartxInmateIds, TxBexarCharges, TxBexarBonds, TxBexarArrests, TxBexarArrestsAdditional]
    models.each do |model|
      model.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    end
  end
  
  def finish
    @run_object.finish
  end
end
