require_relative '../models/ky_runs'
require_relative '../models/ky_general_info'
require_relative '../models/ky_administrators'
require_relative '../models/ky_enrollment'
require_relative '../models/ky_schools_assessment'
require_relative '../models/ky_schools_assessment_by_levels'
require_relative '../models/ky_assessment_act'
require_relative '../models/ky_assesment_national'
require_relative '../models/ky_graduation_rate'
require_relative '../models/ky_safety_events'
require_relative '../models/ky_safety_climate'
require_relative '../models/ky_safety_climate_index'
require_relative '../models/ky_safety_audit'
require_relative '../models/ky_safety_audit_measure'

class Keeper
  attr_reader :run_id, :districts, :schools, :ky_general_info, :logger

  def initialize
    super
    @run_object = RunId.new(KyRuns)
    @run_id = @run_object.run_id
    cache_records()
    @logger = Hamster.logger
  end

  def store_administrators(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    check = KyAdministrators.where(md5_hash: hash['md5_hash'], deleted: 0).as_json.first
    if check
      KyAdministrators.udpate_touched_run_id(check['id'], @run_id)
    else
      KyAdministrators.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end


  def store_general_info(hash)
    hash = add_md5_hash_general_info(hash)
    hash = HashWithIndifferentAccess.new(hash)
    check = KyGeneralInfo.where(md5_hash: hash['md5_hash'], deleted: 0).as_json.first
    if check
      KyGeneralInfo.udpate_touched_run_id(check['id'], @run_id)
      check['id']
    else
      record = KyGeneralInfo.new(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
      record.save!
      record.id
    end
  end

  def get_general_id_by_district_name(district_name)
    KyGeneralInfo.where(is_district:1, name: district_name)&.first&.id
  end

  def get_general_id_by_district(district_name, district_code)
    return nil if district_code.nil?
    general_id = @districts.select{|x| x.number == district_code}&.first&.id
    return general_id if general_id.present?
    # create new record
    hash = {name: district_name, number: district_code, is_district: 1}
    hash = add_md5_hash_general_info(hash)
    new_record = KyGeneralInfo.new(hash)
    new_record.save
    cache_records()
    return new_record.id
  end

  def get_general_id_by_name(name)
    general_id = @ky_general_info.select{|x| x["name"] == name }&.first&.id
    return general_id unless general_id.nil?
    # create new record
    hash = {name: name, is_district: 0}
    hash = add_md5_hash(hash)
    new_record = KyGeneralInfo.new(hash)
    new_record.save
    cache_records()
    return new_record.id
  end

  def get_general_id_by_school(school_name, district_code, school_code)
    general_id = @schools.select{|x| x.school_code == school_code}&.first&.id
    return general_id if general_id.present?
    # create new record
    hash = add_md5_hash_general_info({is_district: 0, district_id: nil, number: district_code, name: school_name, school_code: school_code, state_school_id: nil})
    new_record = KyGeneralInfo.new(hash)
    new_record.save
    cache_records()
    return new_record.id
  end

  def cache_records()
    @ky_general_info = KyGeneralInfo.where(deleted: false).to_a  
    @districts  = KyGeneralInfo.where(is_district: 1, deleted: false).to_a
    @schools = KyGeneralInfo.where(is_district: 0, deleted: false).to_a
  end

  def store_safety_audit(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    result = KySafetyAudit.where(md5_hash: hash[:md5_hash], deleted: false)
    audit_id = nil

    if result.present?
      audit_id = result.first.id
    else
      new_record = KySafetyAudit.new(hash)
      new_record.save
      audit_id = new_record.id
    end
    audit_id
  end

  def store_assessment_perfomance_by_grade(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    result = KySchoolsAssessment.where(md5_hash: hash[:md5_hash], deleted: false)
    assessment_id = nil

    if result.present?
      assessment_id = result.first.id
    else
      new_record = KySchoolsAssessment.new(hash)
      new_record.save
      assessment_id = new_record.id
    end
    assessment_id
  end

  def store_assessment_by_levels(list_of_hashes)
    insert_all_in_db(KySchoolsAssessmentByLevels, list_of_hashes)
  end

  def store_assessment_nationals(list_of_hashes)
    logger.debug "started storing assessment_nationals rows: #{list_of_hashes.length}"
    insert_all_in_db(KyAssesmentNational, list_of_hashes)
    logger.debug "started storing assessment_nationals rows: #{list_of_hashes.length}"
  end

  def store_assessment_act(list_of_hashes)
    logger.debug "started storing assessment_act rows: #{list_of_hashes.length}"
    insert_all_in_db(KyAssessmentAct, list_of_hashes)
    logger.debug "finished storing assessment_act rows: #{list_of_hashes.length}"
  end

  def store_graduation_rate(list_of_hashes)
    logger.debug "started storing graduation_rate rows: #{list_of_hashes.length}"
    insert_all_in_db(KyGraduationRate, list_of_hashes)
    logger.debug "finished storing graduation_rate rows: #{list_of_hashes.length}"
  end

  def store_safety_climate(list_of_hashes)
    insert_all_in_db(KySafetyClimate, list_of_hashes)
  end
  
  def store_safety_climate_index(list_of_hashes)
    logger.debug "started storing safety_climate_index rows: #{list_of_hashes.length}"
    insert_all_in_db(KySafetyClimateIndex, list_of_hashes)
    logger.debug "finished storing safety_climate_index rows: #{list_of_hashes.length}"
  end

  def store_safety_audit_measures(list_of_hashes)
    # logger.debug "started storing safety_audit_measures rows: #{list_of_hashes.length}"
    insert_all_in_db(KySafetyAuditMeasure, list_of_hashes)
    # logger.debug "finished storing safety_audit_measures rows: #{list_of_hashes.length}"
  end

  def store_school_safety(list_of_hashes)
    logger.debug "started storing school_safety rows: #{list_of_hashes.length}"
    insert_all_in_db(KySafetyEvents, list_of_hashes)
    logger.debug "finished storing school_safety rows: #{list_of_hashes.length}"
  end

  def store_enrollments(list_of_hashes)
    insert_all_in_db(KyEnrollment, list_of_hashes)
  end

  def insert_all_in_db(model, list_of_hashes)
    list_of_hashes = list_of_hashes.map{|hash| add_md5_hash(hash)}
    splits = list_of_hashes.each_slice(10000).to_a
    splits.each do |split|
      model.insert_all(split)
    end 
  end

  def finish
    @run_object.finish
  end

  private
  
  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    hash
  end

  def add_md5_hash_general_info(hash)
    new_hash = hash.slice(*general_info_params)
    hash['md5_hash'] = Digest::MD5.hexdigest(new_hash.to_s)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    hash
  end

  def general_info_params
    [:is_district, :district_id, :number, :name, :school_code, :state_school_id]
  end


end