# require model files here
require_relative '../models/mississippi_inmates_run'
require_relative '../models/mississippi_inmate'
require_relative '../models/mississippi_inmate_id'
require_relative '../models/mississippi_inmate_additional_info'
require_relative '../models/mississippi_mugshot'
require_relative '../models/mississippi_physical_location_history'
require_relative '../models/mississippi_court_address'
require_relative '../models/mississippi_arrest'
require_relative '../models/mississippi_charge'
require_relative '../models/mississippi_court_hearing'
require_relative '../models/mississippi_holding_facility'

class Keeper
  MAX_BUFFER_SIZE = 150
  attr_reader :run_id

  include Hamster::Loggable

  def initialize
    super
    @run_object = RunId.new(MississippiInmatesRun)
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
      'MississippiInmateId': [],
      'MississippiInmateAdditionalInfo': [],
      'MississippiPhysicalLocationHistory': [],
      'MississippiMugshot': [],
      'MississippiHoldingFacility': [],
    }
    @buffer.each do |inmate_data|
      begin
        inmate_hash = inmate_data['MississippiInmate'].merge(md5_hash: create_md5_hash(inmate_data['MississippiInmate']))
        inmate = MississippiInmate.create_and_update!(@run_id, inmate_hash)      
        arrest = MississippiArrest.create_and_update!(inmate)
        child_buffer[:'MississippiInmateId'] << regenerate_hash(inmate, inmate_data['MississippiInmateId'])
        child_buffer[:'MississippiInmateAdditionalInfo'] << regenerate_hash(inmate, inmate_data['MississippiInmateAdditionalInfo'])
        child_buffer[:'MississippiPhysicalLocationHistory'] << regenerate_hash(inmate, inmate_data['MississippiPhysicalLocationHistory'])
        child_buffer[:'MississippiMugshot'] << regenerate_hash(inmate, inmate_data['MississippiMugshot'])
        child_buffer[:'MississippiHoldingFacility'] << regenerate_hash(arrest, inmate_data['MississippiHoldingFacility'])
        inmate_data['MississippiCharge'].each do |item|
          hearing_data  = inmate_data['MississippiCourtHearing'].select{|i| i[:charge_key] == item[:description]}.first
          charge        = MississippiCharge.create_and_update!(arrest, item)
          court_address = MississippiCourtAddress.create_and_update!(@run_id, hearing_data[:hearing_data])
          MississippiCourtHearing.create_and_update!(charge, court_address, hearing_data)
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
      data_array = []
      model_klass = k.to_s.constantize
      if k.to_s == 'MississippiHoldingFacility'
        run_ids = Hash[model_klass.where( arrest_id: v.map { |h| h[:arrest_id] } ).map { |r| [r.arrest_id, r.run_id] }]
        v.each do |hash|
          data_array << hash.merge(run_id: run_ids[hash[:arrest_id]] || @run_id, updated_at: Time.now)
        end
      else
        run_ids = Hash[model_klass.where( inmate_id: v.map { |h| h[:inmate_id] } ).map { |r| [r.inmate_id, r.run_id] }]
        v.each do |hash|
          data_array << hash.merge(run_id: run_ids[hash[:inmate_id]] || @run_id, updated_at: Time.now)
        end
      end

      model_klass.upsert_all(data_array)
      Hamster.close_connection(model_klass)
    end
    close_connections
  end

  def update_history
    models = [MississippiArrest, MississippiCharge, MississippiCourtAddress, MississippiCourtHearing,
              MississippiHoldingFacility, MississippiInmateAdditionalInfo, MississippiInmate,
              MississippiInmateId, MississippiMugshot, MississippiPhysicalLocationHistory]
    models.each do |model|
      model.update_history!(@run_id)
    end
  end

  def finish
    @run_object.finish
  end

  private

  def close_connections
    [MississippiInmate, MississippiArrest, MississippiCharge, MississippiCourtAddress, MississippiCourtHearing].each do |model|
      Hamster.close_connection(model)
    end
  end

  def regenerate_hash(object, hash_data)
    if object.is_a?(MississippiInmate)
      data = hash_data.merge(inmate_id: object.id)
    elsif object.is_a?(MississippiArrest)
      data = hash_data.merge(arrest_id: object.id)
    end
    data.merge(md5_hash: create_md5_hash(data), touched_run_id: @run_id)
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end
