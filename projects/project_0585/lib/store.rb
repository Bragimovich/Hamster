require_relative '../models/raw_tributearchive_ceo_setting'
require_relative '../models/raw_tributearchive_funeral_home'
require_relative '../models/raw_tributearchive'
require_relative '../models/tributearchive_setting'
require_relative '../models/raw_tributearchive_memorial'
require_relative '../models/raw_tributearchive_runs'
require_relative '../models/tribalarchive_problem_persons'
require_relative '../lib/string'

class Store < Hamster::Parser
  MAX_BUFFER_SIZE = 100

  def initialize
    super
    @run_object = RunId.new(RawTributearchiveRuns)
    @run_id = @run_object.run_id
    @buffer = []
  end
  
  def store_data(data_hash)
    @buffer << data_hash

    flush if @buffer.count >= MAX_BUFFER_SIZE
  end

  def flush
    return if @buffer.count.zero?

    tribute_hash_array = []
    ceo_setting_hash_array = []
    funeral_home_hash_array = []
    setting_hash_array = []
    memorial_hash_array = []
    
    # tribute_db_run_ids = Hash[RawTributearchive.where( obituary_id: @buffer.map { |h| h[:tributearchive_hash][:obituary_id] } ).map { |r| [r.obituary_id, r.run_id] }]
    # ceo_db_run_ids = Hash[RawTributearchiveCeoSetting.where( obituary_id: @buffer.map { |h| h[:ceo_setting_hash][:obituary_id] } ).map { |r| [r.obituary_id, r.run_id] }]
    # funeral_db_run_ids = Hash[RawTributearchiveFuneralHome.where( obituary_id: @buffer.map { |h| h[:funeral_home_hash][:obituary_id] } ).map { |r| [r.obituary_id, r.run_id] }]
    # setting_db_run_ids = Hash[TributearchiveSetting.where( obituary_id: @buffer.map { |h| h[:setting_hash][:obituary_id] } ).map { |r| [r.obituary_id, r.run_id] }]

    @buffer.each do |data_hash|
      hash = data_hash[:tributearchive_hash]
      tribute_hash_array << hash.merge(touched_run_id: @run_id, run_id: @run_id, updated_at: Time.now)

      hash = data_hash[:ceo_setting_hash]
      ceo_setting_hash_array << hash.merge(touched_run_id: @run_id, run_id: @run_id, updated_at: Time.now)

      hash = data_hash[:funeral_home_hash]
      funeral_home_hash_array << hash.merge(touched_run_id: @run_id, run_id: @run_id, updated_at: Time.now)

      hash = data_hash[:setting_hash]
      setting_hash_array << hash.merge(touched_run_id: @run_id, run_id: @run_id, updated_at: Time.now)
      
      data_hash[:memorial_hash].each do |hash|
        memorial_hash_array << hash.merge(touched_run_id: @run_id, run_id: @run_id, updated_at: Time.now)
      end
    end

    begin
      RawTributearchive.upsert_all(tribute_hash_array)
      RawTributearchiveCeoSetting.upsert_all(ceo_setting_hash_array)
      RawTributearchiveFuneralHome.upsert_all(funeral_home_hash_array)
      TributearchiveSetting.upsert_all(setting_hash_array)
      RawTributearchiveMemorial.upsert_all(memorial_hash_array) unless memorial_hash_array.empty?
      @buffer = []
    rescue Exception=> e
      logger.info e.full_message
      raise e
    end
  end

  def insert_problem_person(obituary_id)
    return if TribalarchiveProblemPersons.where(obituary_id: obituary_id).present?

    TribalarchiveProblemPersons.insert({obituary_id: obituary_id, run_id: @run_id})
  end

  def mark_deleted
    # RawTributearchive.update_history!(@run_id)
    # RawTributearchiveCeoSetting.update_history!(@run_id)
    # RawTributearchiveFuneralHome.update_history!(@run_id)
    # TributearchiveSetting.update_history!(@run_id)
  end

  def finish
    @run_object.finish
  end
end
