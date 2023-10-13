# require model files here
require_relative '../models/al_inmates_run'
require_relative '../models/al_inmate'
require_relative '../models/al_arrest'
require_relative '../models/al_charge'
require_relative '../models/al_court_address'
require_relative '../models/al_court_hearing'
require_relative '../models/al_court_hearings_additional'
require_relative '../models/al_custody_level'
require_relative '../models/al_holding_facilities_additional'
require_relative '../models/al_holding_facility'
require_relative '../models/al_inmate_additional_info'
require_relative '../models/al_inmate_alias'
require_relative '../models/al_inmate_id'
require_relative '../models/al_mugshot'
require_relative '../models/al_inmate_status'
class Keeper
  include Hamster::Loggable
  MAX_BUFFER_SIZE = 250
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(AlInmatesRun)
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
      'AlInmateId': [],
      'AlInmateStatus': [],
      'AlMugshot': [],
      'AlInmateAlias': [],
      'AlInmateAdditionalInfo': [],
      'AlCourtHearingsAdditional': [],
      'AlHoldingFacilitiesAdditional': []
    }
    @buffer.each do |inmate_data|
      inmate_hash = inmate_data['AlInmate'].merge(md5_hash: create_md5_hash(inmate_data['AlInmate']))
      inmate = AlInmate.create_and_update!(@run_id, inmate_hash)
      child_buffer[:'AlInmateId'] << regenerate_hash(inmate, inmate_data['AlInmateId'])
      child_buffer[:'AlInmateStatus'] << regenerate_hash(inmate, inmate_data['AlInmateStatus'])      
      child_buffer[:'AlMugshot'] << regenerate_hash(inmate, inmate_data['AlMugshot'])
      inmate_data['AlInmateAlias'].each do |alias_hash|
        child_buffer[:'AlInmateAlias'] << regenerate_hash(inmate, alias_hash)
      end
      additional_hash = inmate_data['AlInmateAdditionalInfo']
      custody_level = AlCustodyLevel.find_with(additional_hash[:risk_level]&.upcase)
      additional_hash.merge!(custody_level_id: custody_level&.id)
      child_buffer[:'AlInmateAdditionalInfo'] << regenerate_hash(inmate, additional_hash)

      inmate_data['AlArrest'].each do |arrest_hash|
        charge_hashs  = arrest_hash.delete(:charges)
        facility_hash = arrest_hash.delete(:facility)
        arrest = AlArrest.create_and_update!(inmate, arrest_hash)

        charge_hashs.each do |charge_hash|
          court_address_hash = charge_hash['AlCourtAddress']
          court_hearing_hash = charge_hash['AlCourtHearing']
          hearings_additional_hash = charge_hash['AlCourtHearingsAdditional']
          charge = AlCharge.create_and_update!(arrest, charge_hash['AlCharge'])
          court_address = AlCourtAddress.create_and_update!(@run_id, court_address_hash.merge(md5_hash: create_md5_hash(court_address_hash)))
          court_hearing_hash.merge!(court_address_id: court_address.id)
          court_hearing = AlCourtHearing.create_and_update!(charge, court_hearing_hash)
          hearings_additional_hash.each do |additional_hash|
            child_buffer[:'AlCourtHearingsAdditional'] << regenerate_hash(court_hearing, additional_hash)
          end
        end

        facility_additional_hash = facility_hash.delete(:additional_data)
        facility = AlHoldingFacility.create_and_update!(arrest, facility_hash)
        facility_additional_hash.each do |hash|
          child_buffer[:'AlHoldingFacilitiesAdditional'] << regenerate_hash(facility, hash)
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
    models = [AlArrest, AlCharge, AlCourtAddress, AlCourtHearing, AlCourtHearingsAdditional, AlCustodyLevel,
              AlHoldingFacilitiesAdditional, AlHoldingFacility, AlInmateAdditionalInfo, AlInmateAlias,
              AlInmateId, AlInmateStatus, AlInmate, AlMugshot]
    models.each do |model|
      model.update_history!(@run_id)
    end
  end

  def finish
    @run_object.finish
  end

  def generate_custody_levels
    AlCustodyLevel.generate_custody_levels
  end

  private

  def close_connections
    [AlInmate, AlArrest, AlCharge, AlCustodyLevel, AlCourtAddress, AlCourtHearing, AlHoldingFacility].each do |model|
      Hamster.close_connection(model)
    end
  end

  def regenerate_hash(object, hash_data)
    return if hash_data.nil? || hash_data.empty?

    if object.is_a?(AlInmate)
      data = hash_data.merge(inmate_id: object.id)
    elsif object.is_a?(AlCourtHearing)
      data = hash_data.merge(court_hearing_id: object.id)
    elsif object.is_a?(AlCharge)
      data = hash_data.merge(charge_id: object.id)
    elsif object.is_a?(AlHoldingFacility)
      data = hash_data.merge(holding_facility_id: object.id)
    end
    data.merge(md5_hash: create_md5_hash(data), touched_run_id: @run_id)
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end
