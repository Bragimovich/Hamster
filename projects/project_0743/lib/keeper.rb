# require model files here
require_relative '../models/oh_school_run'
require_relative '../models/oh_attendance'
require_relative '../models/oh_educator'
require_relative '../models/oh_enrollment'
require_relative '../models/oh_expenditure'
require_relative '../models/oh_general_info'
require_relative '../models/oh_gifted'
require_relative '../models/oh_graduation'
require_relative '../models/oh_performance'
class Keeper < Hamster::Keeper
  MAX_BUFFER_SIZE = 100
  attr_reader :run_id

  def initialize
    super
    @run_object = RunId.new(OhSchoolRun)
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

  def get_general_info(school_code, school_name, dist_code, dist_name, data_source)
    if dist_code.presence && school_code.presence
      general_info = OhGeneralInfo.where("number='#{school_code}' AND district_id IN (SELECT id FROM oh_general_info WHERE number='#{dist_code}' AND is_district=1)").first
      if general_info.nil?
        dist_general_info = OhGeneralInfo.find_by(number: dist_code.to_s, is_district: 1)
        if dist_general_info.nil?
          hash_data = {is_district: 1, number: dist_code, name: dist_name, data_source_url: data_source}
          dist_general_info = OhGeneralInfo.create_and_update!(@run_id, hash_data)
        end
        hash_data = {is_district: 0, number: school_code, name: school_name, district_id: dist_general_info.id, data_source_url: data_source}
        general_info = OhGeneralInfo.create_and_update!(@run_id, hash_data)
      end
    elsif school_code.nil? && dist_code.presence
      general_info = OhGeneralInfo.find_by(number: dist_code.to_s, is_district: 1)
      if general_info.nil?
        hash_data = {is_district: 1, number: dist_code, name: dist_name, data_source_url: data_source}
        general_info = OhGeneralInfo.create_and_update!(@run_id, hash_data)
      end
    elsif school_code.nil? && dist_code.nil? && dist_name
      general_info = OhGeneralInfo.find_by(name: dist_name)
      if general_info.nil?
        hash_data = {name: dist_name, type: 'State', state: 'OH', data_source_url: data_source}
        general_info = OhGeneralInfo.create_and_update!(@run_id, hash_data)
      end
    else
      logger.info "#{'='*10} => #{dist_name}, #{school_name}, #{data_source}"
    end
    general_info
  end

  def sync_general_info_table
    manual_data = []
    manual_data << {is_district: nil, number: 0, name: 'Ohio', type: 'State', state: 'OH', data_source_url: "manual value"}
    manual_data.each do |hash_data|
      OhGeneralInfo.create_and_update!(@run_id, hash_data)
    end
    UsDistricts.where(state: "OH").each do |row|
      hash = row.as_json(only: %i(number name nces_id type phone county address city state zip zip_4))
      hash[:is_district] = 1
      hash[:data_source_url] = "db01.us_schools_raw.us_districts##{row.id}"
      hash[:md5_hash] = Digest::MD5.hexdigest(hash.to_s)
      OhGeneralInfo.create_and_update!(@run_id, hash)
    end

    UsSchools.where(state: "OH").each do |row|
      hash = row.as_json(only: %i(number name nces_id type phone county address city state zip zip_4 low_grade high_grade charter magnet title_1_school title_1_school_wide))
      hash[:is_district] = 0
      hash[:district_id] = OhGeneralInfo.find_by(is_district: 1, number: row.district_number)&.id
      hash[:data_source_url] = "db01.us_schools_raw.us_schools##{row.id}"
      hash[:md5_hash] = Digest::MD5.hexdigest(hash.to_s)
      OhGeneralInfo.create_and_update!(@run_id, hash)
    end
  end

  def finish
    @run_object.finish
  end
end
