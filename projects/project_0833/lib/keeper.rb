# require model files here
require_relative '../models/wa_snohomish_inmates_run'
require_relative '../models/wa_snohomish_inmate'
require_relative '../models/wa_snohomish_arrest'
require_relative '../models/wa_snohomish_charge'
require_relative '../models/wa_snohomish_bond'
require_relative '../models/wa_snohomish_charges_additional'
require_relative '../models/wa_snohomish_court_hearing.rb'
require_relative '../models/wa_snohomish_holding_facility'
require_relative '../models/wa_snohomish_inmate_additional_info'
require_relative '../models/wa_snohomish_inmate_id'
require_relative '../models/wa_snohomish_inmate_status'

class Keeper
  include Hamster::Loggable
  MAX_BUFFER_SIZE = 100
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(WaSnohomishInmatesRun)
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
      'WaSnohomishInmateStatus': [],
      'WaSnohomishInmateId': [],
      'WaSnohomishInmateAdditionalInfo': [],
      'WaSnohomishHoldingFacility': [],
      'WaSnohomishChargesAdditional': [],
      'WaSnohomishBond': [],
      'WaSnohomishCourtHearing': []
    }
    @buffer.each do |inmate_data|
      inmate_hash = inmate_data['WaSnohomishInmate'].merge(md5_hash: create_md5_hash(inmate_data['WaSnohomishInmate']))
      inmate = WaSnohomishInmate.create_and_update!(@run_id, inmate_hash)
      child_buffer[:'WaSnohomishInmateStatus'] << regenerate_hash(inmate, inmate_data['WaSnohomishInmateStatus'])
      child_buffer[:'WaSnohomishInmateId'] << regenerate_hash(inmate, inmate_data['WaSnohomishInmateId'])
      child_buffer[:'WaSnohomishInmateAdditionalInfo'] << regenerate_hash(inmate, inmate_data['WaSnohomishInmateAdditionalInfo'])
      inmate_data['arrest_data'].each do |arrest_hash|
        holding_data = arrest_hash.delete(:holding_data)
        charges_data = arrest_hash.delete(:charges_data)
        arrest = WaSnohomishArrest.create_and_update!(inmate, arrest_hash)
        child_buffer[:'WaSnohomishHoldingFacility'] << regenerate_hash(arrest, holding_data)
        charges_data.each do |charge_hash|
          additional_data = charge_hash.delete(:additional_data)
          bond_data = charge_hash.delete(:bond_data)
          hearing_data = charge_hash.delete(:hearing_data)
          charge = WaSnohomishCharge.create_and_update!(arrest, charge_hash)
          additional_data.each do |additional_hash|
            child_buffer[:'WaSnohomishChargesAdditional'] << regenerate_hash(charge, additional_hash) if additional_hash
          end
          bond_data.each do |bond_hash|
            child_buffer[:'WaSnohomishBond'] << regenerate_hash(arrest, bond_hash.merge(charge_id: charge.id)) if bond_hash
          end
          hearing_data.each do |hearing_court_hash|
            child_buffer[:'WaSnohomishCourtHearing'] << regenerate_hash(charge, hearing_court_hash)
          end
        end
      end
    end
    child_buffer
  end

  def flush(hash_data)
    hash_data.each do |k, v|
      next if v.nil? || v.empty? || v.compact.empty?

      v = v.compact
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
    models = [WaSnohomishArrest, WaSnohomishBond, WaSnohomishCharge, WaSnohomishChargesAdditional,
              WaSnohomishCourtHearing, WaSnohomishHoldingFacility, WaSnohomishInmateAdditionalInfo,
              WaSnohomishInmateId, WaSnohomishInmateStatus, WaSnohomishInmate]
    models.each do |model|
      model.update_history!(@run_id)
    end
  end

  def finish
    @run_object.finish
  end

  private

  def close_connections
    [WaSnohomishInmate, WaSnohomishArrest, WaSnohomishCharge].each do |model|
      Hamster.close_connection(model)
    end
  end

  def regenerate_hash(object, hash_data)
    return if hash_data.nil? || hash_data.empty?

    if object.is_a?(WaSnohomishInmate)
      data = hash_data.merge(inmate_id: object.id)
    elsif object.is_a?(WaSnohomishArrest)
      data = hash_data.merge(arrest_id: object.id)
    elsif object.is_a?(WaSnohomishCharge)
      data = hash_data.merge(charge_id: object.id)
    end
    data.merge(md5_hash: create_md5_hash(data), touched_run_id: @run_id)
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end
