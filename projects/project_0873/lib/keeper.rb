# require model files here
require_relative '../models/nj_doc_inmates_run'
require_relative '../models/nj_doc_inmate'
require_relative '../models/nj_doc_arrest'
require_relative '../models/nj_doc_charge'
require_relative '../models/nj_doc_court_hearing'
require_relative '../models/nj_doc_court_address'
require_relative '../models/nj_doc_holding_facility'
require_relative '../models/nj_doc_inmate_additional_info'
require_relative '../models/nj_doc_inmate_alias'
require_relative '../models/nj_doc_inmate_id'
require_relative '../models/nj_doc_mugshot'
require_relative '../models/nj_doc_parole_booking_date'
class Keeper
  include Hamster::Loggable
  MAX_BUFFER_SIZE = 150
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NjDocInmatesRun)
    @run_id = @run_object.run_id
    @buffer = []
  end

  def store(hash_data)
    logger.debug "Keeping data - SBI: #{hash_data['NjDocInmateId'][:number]}, full name: #{hash_data['NjDocInmate'][:full_name]}"
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
      'NjDocInmateId': [],
      'NjDocMugshot': [],
      'NjDocInmateAlias': [],
      'NjDocInmateAdditionalInfo': [],
      'NjDocParoleBookingDate': [],
      'NjDocHoldingFacility': [],
      'NjDocCourtHearing': []
    }
    @buffer.each do |inmate_data|
      inmate_hash = inmate_data['NjDocInmate'].merge(md5_hash: create_md5_hash(inmate_data['NjDocInmate']))
      inmate = NjDocInmate.create_and_update!(@run_id, inmate_hash)
      child_buffer[:'NjDocInmateId'] << regenerate_hash(inmate, inmate_data['NjDocInmateId'])
      child_buffer[:'NjDocInmateAdditionalInfo'] << regenerate_hash(inmate, inmate_data['NjDocInmateAdditionalInfo'])
      child_buffer[:'NjDocMugshot'] << regenerate_hash(inmate, inmate_data['NjDocMugshot'])
      child_buffer[:'NjDocParoleBookingDate'] << regenerate_hash(inmate, inmate_data['NjDocParoleBookingDate'])
      inmate_data['NjDocInmateAlias'].each do |alias_hash|
        child_buffer[:'NjDocInmateAlias'] << regenerate_hash(inmate, alias_hash)
      end

      arrest = NjDocArrest.create_and_update!(inmate, inmate_data['NjDocArrest'])
      child_buffer[:'NjDocHoldingFacility'] << regenerate_hash(arrest, inmate_data['NjDocHoldingFacility'])
      inmate_data['NjDocCharge'].each do |charge_hash|
        court_hearing_hash = charge_hash.delete(:court_hearing_data)
        charge = NjDocCharge.create_and_update!(arrest, charge_hash)
        court_address_hash = court_hearing_hash.delete(:court_address)
        court_address = NjDocCourtAddress.create_and_update!(@run_id, court_address_hash.merge(md5_hash: create_md5_hash(court_address_hash)))
        court_hearing_hash.merge!(court_address_id: court_address.id)
        child_buffer[:'NjDocCourtHearing'] << regenerate_hash(charge, court_hearing_hash)
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
    models = [NjDocArrest, NjDocCharge, NjDocCourtAddress, NjDocCourtHearing, NjDocHoldingFacility,
              NjDocInmateAdditionalInfo, NjDocInmateAlias, NjDocInmateId, NjDocInmate, NjDocMugshot,
              NjDocParoleBookingDate]
    models.each do |model|
      model.update_history!(@run_id)
    end
  end

  def finish
    @run_object.finish
  end

  private

  def close_connections
    [NjDocInmate, NjDocArrest, NjDocCharge, NjDocCourtAddress].each do |model|
      Hamster.close_connection(model)
    end
  end

  def regenerate_hash(object, hash_data)
    return if hash_data.nil? || hash_data.empty?

    if object.is_a?(NjDocInmate)
      data = hash_data.merge(inmate_id: object.id)
    elsif object.is_a?(NjDocArrest)
      data = hash_data.merge(arrest_id: object.id)
    elsif object.is_a?(NjDocCharge)
      data = hash_data.merge(charge_id: object.id)
    end
    data.merge(md5_hash: create_md5_hash(data), touched_run_id: @run_id)
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end
