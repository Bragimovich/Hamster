require_relative '../models/wi_general_info'
require_relative '../models/us_districts'
require_relative '../models/wisconsin_report_card_runs'
require_relative '../models/wi_enrollment'
require_relative '../models/wi_assessment_wsas'
require_relative '../models/wi_assessment_act'
require_relative '../models/wi_assessment_act_grad'
require_relative '../models/wi_assessment_aspire'
require_relative '../models/wi_assessment_forward'
require_relative '../models/wi_discipline_action'
require_relative '../models/wi_discipline_incident'
require_relative '../models/wi_attendance'
require_relative '../models/wi_dropout'

class Keeper
  MAX_BUFFER_SIZE = 1000
  attr_accessor :wi_general_districts, :wi_general_schools, :wi_general_info

  def initialize
    @run_object = RunId.new(WisconsinReportCardRuns)
    @run_id = @run_object.run_id
    @buffer = []
  end

  def store(hash_data, model_name)
    @buffer << hash_data

    flush(model_name) if @buffer.size >= MAX_BUFFER_SIZE
  end

  def flush(model_name)
    data_array = []
    object     = model_name.constantize    
    run_ids    = Hash[object.where( md5_hash: @buffer.map { |h| h[:md5_hash] } ).map { |r| [r.md5_hash, r.run_id] }]
    @buffer.each do |hash|
      data_array << hash.merge(run_id: run_ids[hash[:md5_hash]] || @run_id, touched_run_id: @run_id, updated_at: Time.now)
    end
    object.upsert_all(data_array) if data_array.any?
    @buffer = []
  end

  def get_general_info(dist_code, school_code, dist_name, school_name, data_source)
    if dist_name == '[Statewide]' && school_name == '[Statewide]'
      general_info = WiGeneralInfo.find_by(number: 0, name: '[Statewide]')
    elsif school_name == '[Districtwide]'
      general_info = WiGeneralInfo.where("number=? AND LOWER(name) LIKE ?", dist_code.to_s, "%#{dist_name.split.first}%").first
      if general_info.nil?
        hash_data = {is_district: 1, number: dist_code, name: dist_name, type: nil, data_source_url: data_source}
        general_info = WiGeneralInfo.create_and_update!(@run_id, hash_data)
      end
    elsif dist_code.presence && school_code.presence
      general_info = WiGeneralInfo.where("number='#{school_code}' AND district_id IN (SELECT id FROM wi_general_info WHERE number='#{dist_code}' AND is_district=1)").first
      if general_info.nil?
        dist_general_info = WiGeneralInfo.where("number=? AND is_district=1 AND LOWER(name) LIKE ?", dist_code.to_s, "%#{dist_name.split.first}%").first
        if dist_general_info.nil?
          hash_data = {is_district: 1, number: dist_code, name: dist_name, data_source_url: data_source}
          dist_general_info = WiGeneralInfo.create_and_update!(@run_id, hash_data)
        end
        hash_data = {is_district: 0, number: school_code, name: school_name, district_id: dist_general_info.id, data_source_url: data_source}
        general_info = WiGeneralInfo.create_and_update!(@run_id, hash_data)
      end
    else
      logger.info "#{'='*10} => #{dist_name}, #{school_name}, #{data_source}"
    end
    general_info
  end

  def sync_general_info_table
    manual_data = []
    manual_data << {is_district: 1, number: 0, name: '[Statewide]', type: nil, data_source_url: "manual value"}
    manual_data << {is_district: 1, number: 0, name: '[Districtwide]', type: nil, data_source_url: "manual value"}
    manual_data.each do |hash_data|
      WiGeneralInfo.create_and_update!(@run_id, hash_data)
    end
    wi_districts = UsDistricts.where(state: "WI").as_json(only: [:number, :name, :nces_id,:type,:phone, :address,:city, :state, :zip, :zip_4, :data_source_url])
    wi_districts.each do |hash|
      hash[:is_district] = 1
      store_general_info(hash)
    end
    wi_schools = UsSchools.where(state: "WI").as_json(only: [:district_number, :number, :name, :low_grade, :high_grade, :charter, :magnet, :title_1_school, :title_1_school_wide, :nces_id, :type, :phone, :address, :city, :state, :zip, :zip_4, :data_source_url])
    wi_schools.each do |hash|
      hash[:is_district] = 0
      hash[:district_id] = WiGeneralInfo.where(is_district: 1, number: hash["district_number"])&.first&.id
      hash.delete("district_number")
      store_general_info(hash)
    end
  end

  def store_general_info(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    check = WiGeneralInfo.find_by(md5_hash: hash['md5_hash'], deleted: 0)
    if check
      check.update(touched_run_id: @run_id)
    else
      WiGeneralInfo.insert(hash)
    end
  end

  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    hash
  end

  def finish
    @run_object.finish
  end
end
