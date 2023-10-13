# require model files here
require_relative '../models/tx_fort_bend_inmate_run'
require_relative '../models/tx_fort_bend_arrest'
require_relative '../models/tx_fort_bend_bond'
require_relative '../models/tx_fort_bend_charge_additional'
require_relative '../models/tx_fort_bend_charge'
require_relative '../models/tx_fort_bend_inmate_additional_info'
require_relative '../models/tx_fort_bend_inmate_id'
require_relative '../models/tx_fort_bend_inmate'
require_relative '../models/tx_fort_bend_mugshot'

class Keeper
  MAX_BUFFER_SIZE = 200
  attr_reader :run_id

  def initialize
    super
    @run_object = RunId.new(TxFortBendInmateRun)
    @run_id = @run_object.run_id
    @buffer = []
  end

  def store(hash_data)
    @buffer << hash_data

    regenerate_and_flush if @buffer.count >= MAX_BUFFER_SIZE
  end

  def regenerate_and_flush
    return if @buffer.count.zero?

    flush regenerate
    @buffer = []
  end

  def regenerate
    return if @buffer.count.zero?

    child_buffer = {
      'TxFortBendInmateId': [],
      'TxFortBendInmateAdditionalInfo': [],
      'TxFortBendMugshot': [],
      'TxFortBendChargeAdditional': [],
      'TxFortBendBond': []
    }

    @buffer.each do |inmate_data|
      inmate_hash = inmate_data['TxFortBendInmate'].merge(md5_hash: create_md5_hash(inmate_data['TxFortBendInmate']))
      inmate = TxFortBendInmate.create_and_update!(@run_id, inmate_hash)
      arrest = TxFortBendArrest.create_and_update!(inmate, inmate_data['TxFortBendArrest'])
      child_buffer[:'TxFortBendInmateId'] << regenerate_hash(inmate, inmate_data['TxFortBendInmateId'])
      child_buffer[:'TxFortBendInmateAdditionalInfo'] << regenerate_hash(inmate, inmate_data['TxFortBendInmateAdditionalInfo'])
      child_buffer[:'TxFortBendMugshot'] << regenerate_hash(inmate, inmate_data['TxFortBendMugshot'])
      inmate_data['TxFortBendCharge'].each do |item|
        additional_info = item.delete(:additional)
        bond = item.delete(:bond)
        charge = TxFortBendCharge.create_and_update!(arrest, item)
        child_buffer[:'TxFortBendChargeAdditional'].concat(charge_additional_info(charge, additional_info))
        child_buffer[:'TxFortBendBond'] << regenerate_hash(arrest, bond.merge(charge_id: charge.id))
      end
    end
    child_buffer
  end

  def flush(hash_data)
    hash_data.each do |k, v|
      data_array = []
      model_klass = k.to_s.constantize
      run_ids = Hash[model_klass.where( md5_hash: v.map { |h| h[:md5_hash] } ).map { |r| [r.md5_hash, r.run_id] }]
      v.each do |hash|
        data_array << hash.merge(run_id: run_ids[hash[:md5_hash]] || @run_id, updated_at: Time.now)
      end
      
      model_klass.upsert_all(data_array)
      Hamster.close_connection(model_klass)
    end
    close_connections
  end

  def update_history
    models = [TxFortBendInmate, TxFortBendArrest, TxFortBendBond, TxFortBendChargeAdditional,
              TxFortBendCharge, TxFortBendInmateAdditionalInfo, TxFortBendInmateId, TxFortBendMugshot]
    models.each do |model|
      model.update_history!(@run_id)
    end
  end

  def finish
    @run_object.finish
  end

  private

  def close_connections
    [TxFortBendInmate, TxFortBendArrest, TxFortBendCharge].each do |model|
      Hamster.close_connection(model)
    end
  end

  def regenerate_hash(object, hash_data)
    if object.is_a?(TxFortBendInmate)
      data = hash_data.merge(inmate_id: object.id)
    elsif object.is_a?(TxFortBendArrest)
      data = hash_data.merge(arrest_id: object.id)
    end
    data.merge(md5_hash: create_md5_hash(data), touched_run_id: @run_id)
  end

  def charge_additional_info(charge, additional_info)
    info = []
    additional_info.each do |k,v|
      data = {
        charge_id: charge.id,
        key: k,
        value: v
      }
      info << data.merge(md5_hash: create_md5_hash(data), touched_run_id: @run_id)
    end
    info
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end
