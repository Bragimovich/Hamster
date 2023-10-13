# require model files here
require_relative '../models/fl_hillsborough_inmates_run'
require_relative '../models/fl_hillsborough_inmate'
require_relative '../models/fl_hillsborough_arrest'
require_relative '../models/fl_hillsborough_bond'
require_relative '../models/fl_hillsborough_charge'
require_relative '../models/fl_hillsborough_charges_additional'
require_relative '../models/fl_hillsborough_court_hearing'
require_relative '../models/fl_hillsborough_holding_facility'
require_relative '../models/fl_hillsborough_inmate_additional_info'
require_relative '../models/fl_hillsborough_inmate_address'
require_relative '../models/fl_hillsborough_inmate_alias'
require_relative '../models/fl_hillsborough_inmate_id'
require_relative '../models/fl_hillsborough_mugshot'

class Keeper
  include Hamster::Loggable
  MAX_BUFFER_SIZE = 150
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(FlHillsboroughInmatesRun)
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
      'FlHillsboroughInmateId': [],
      'FlHillsboroughMugshot': [],
      'FlHillsboroughInmateAdditionalInfo': [],
      'FlHillsboroughInmateAddresses': [],
      'FlHillsboroughInmateAlias': [],
      'FlHillsboroughHoldingFacility': [],
      'FlHillsboroughCourtHearing': [],
      'FlHillsboroughBond': [],
      'FlHillsboroughChargesAdditional': []
    }
    @buffer.each do |inmate_data|
      begin
        inmate_hash = inmate_data['FlHillsboroughInmate'].merge(md5_hash: create_md5_hash(inmate_data['FlHillsboroughInmate']))
        inmate = FlHillsboroughInmate.create_and_update!(@run_id, inmate_hash)
        child_buffer[:'FlHillsboroughInmateId'] << regenerate_hash(inmate, inmate_data['FlHillsboroughInmateId'])
        child_buffer[:'FlHillsboroughMugshot'] << regenerate_hash(inmate, inmate_data['FlHillsboroughMugshot'])
        child_buffer[:'FlHillsboroughInmateAdditionalInfo'] << regenerate_hash(inmate, inmate_data['FlHillsboroughInmateAdditionalInfo'])
        child_buffer[:'FlHillsboroughInmateAddresses'] << regenerate_hash(inmate, inmate_data['FlHillsboroughInmateAddresses'])
        inmate_data['FlHillsboroughInmateAlias'].each do |alias_hash|
          child_buffer[:'FlHillsboroughInmateAlias'] << regenerate_hash(inmate, alias_hash)
        end
        arrest = FlHillsboroughArrest.create_and_update!(inmate, inmate_data['FlHillsboroughArrest'])
        child_buffer[:'FlHillsboroughHoldingFacility'] << regenerate_hash(arrest, inmate_data['FlHillsboroughHoldingFacility'])
        inmate_data['FlHillsboroughCharge'].each do |charge_hash|
          court_hearing_data = charge_hash.delete(:court_hearing_data)
          bond_data          = charge_hash.delete(:bond_data)
          additional_data    = charge_hash.delete(:additional_data)
          
          charge = FlHillsboroughCharge.create_and_update!(arrest, charge_hash)
          
          child_buffer[:'FlHillsboroughCourtHearing'] << regenerate_hash(charge, court_hearing_data)
          child_buffer[:'FlHillsboroughBond'] << regenerate_hash(charge, bond_data.merge(arrest_id: arrest.id))
          additional_data.each do |charge_additional_hash|
            child_buffer[:'FlHillsboroughChargesAdditional'] << regenerate_hash(charge, charge_additional_hash)
          end
        end
      rescue => e
        logger.info inmate_data

        next
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
    models = [FlHillsboroughArrest, FlHillsboroughBond, FlHillsboroughCharge, FlHillsboroughChargesAdditional,
              FlHillsboroughCourtHearing, FlHillsboroughHoldingFacility, FlHillsboroughInmateAdditionalInfo,
              FlHillsboroughInmateAddresses, FlHillsboroughInmateAlias, FlHillsboroughInmateId,
              FlHillsboroughInmate, FlHillsboroughMugshot]
    models.each do |model|
      model.update_history!(@run_id)
    end
  end

  def finish
    @run_object.finish
  end

  private

  def close_connections
    [FlHillsboroughInmate, FlHillsboroughArrest, FlHillsboroughCharge].each do |model|
      Hamster.close_connection(model)
    end
  end

  def regenerate_hash(object, hash_data)
    return if hash_data.nil? || hash_data.empty?

    if object.is_a?(FlHillsboroughInmate)
      data = hash_data.merge(inmate_id: object.id)
    elsif object.is_a?(FlHillsboroughArrest)
      data = hash_data.merge(arrest_id: object.id)
    elsif object.is_a?(FlHillsboroughCharge)
      data = hash_data.merge(charge_id: object.id)
    end
    data.merge(md5_hash: create_md5_hash(data), touched_run_id: @run_id)
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end
