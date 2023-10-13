require_relative '../models/ct_runs'
require_relative '../models/ct_enrollment'
require_relative '../models/ct_general_info'
require_relative '../models/ct_assesment'
require_relative '../models/ct_district_expenditures'
require_relative '../models/ct_assessment_by_levels'
require_relative '../models/ct_assessment_ssa_index'
require_relative '../models/us_districts'

class Keeper
  attr_accessor :districts, :schools, :ct_general_info

  def initialize
    @run_object = RunId.new(CtRuns)
    @run_id = @run_object.run_id
    cache_records()
  end

  def sync_general_info_table
    ct_districts = UsDistricts.where(state: "CT").as_json(only: [:number, :name, :nces_id,:type,:phone, :county, :address,:city, :state, :zip, :zip_4])
    ct_districts.each do |hash|
      hash[:data_source_url] = 'DB01.us_schools_raw.us_districts'
      hash[:is_district] = 1
      store_general_info(hash)
    end
    ct_schools = UsSchools.where(state: "CT").as_json(only: [:district_number, :number, :name, :low_grade, :high_grade, :charter, :magnet, :title_1_school, :title_1_school_wide, :nces_id, :type, :phone, :address, :city, :state, :zip, :zip_4])
    ct_schools.each do |hash|
      hash[:is_district] = 0
      hash[:data_source_url] = 'DB01.us_schools_raw.us_schools'
      hash[:district_id] = CtGeneralInfo.where(is_district: 1, number: hash["district_number"])&.first&.id
      hash.delete("district_number")
      store_general_info(hash)
    end
  end

  def store_general_info(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    check = CtGeneralInfo.where(md5_hash: hash['md5_hash'], deleted: 0).as_json.first
    if check
      CtGeneralInfo.udpate_touched_run_id(check['id'],@run_id)
    else
      CtGeneralInfo.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def store_district_expenditures(list_of_hashes)
    insert_all_in_db(CtDistrictExpenditure, list_of_hashes)
  end

  def store_schools_assesment_ssa_index(list_of_hashes)
    insert_all_in_db(CtSchoolAssessmentSSAIndex, list_of_hashes)
  end

  def store_schools_assesments_by_level(list_of_hashes)
    insert_all_in_db(CtSchoolAssessmentByLevels, list_of_hashes)
  end

  def store_enrollments(list_of_hashes)
    insert_all_in_db(CtEnrollment, list_of_hashes)
  end

  def get_general_id_by_district_name_prime(district_name)
    @districts.select{|x| x.name == district_name}&.first&.id
  end

  def get_general_id_by_name(name)
    general_id = @ct_general_info.select{|x| x["name"] == name }&.first&.id

    unless general_id.nil?
      return general_id
    end

    # create new record
    hash = {name: name, is_district: 1}
    hash = add_md5_hash(hash)
    new_record = CtGeneralInfo.new(hash)
    new_record.save
    cache_records()
    return new_record.id
  end

  def get_general_id_by_district(district_name, district_code)
    return nil if district_code.nil?
    general_id = @districts.select{|x| x.number == district_code }&.first&.id
    return general_id if general_id.present?

    hash = {name: district_name, number: district_code, is_district: 1}
    hash = add_md5_hash(hash)
    new_record = CtGeneralInfo.new(hash)
    new_record.save
    cache_records()
    return new_record.id
  end

  def get_general_id_by_school(school_name, school_code, district_id)
    general_id = @schools.select{|x| x.number == school_code}&.first&.id
    return general_id if general_id.present?

    hash = add_md5_hash({number: school_code, district_id: district_id, name: school_name, is_district: 0})
    new_record = CtGeneralInfo.new(hash)
    new_record.save
    cache_records()
    return new_record.id
  end

  def store_school_assesments(hash)
    hash = add_md5_hash(hash)
    check = CtSchoolAssessments.where(md5_hash: hash['md5_hash'], deleted: false)
    if check.present?
      return check.first.id
    else
      assement = CtSchoolAssessments.new(hash)
      assement.save
      return assement.id
    end
  end
  
  def finish
    @run_object.finish
  end
  
  private
  
  def cache_records()
    @ct_general_info = CtGeneralInfo.where(deleted: false).to_a  
    @districts  = CtGeneralInfo.where(is_district: 1, deleted: false).to_a
    @schools = CtGeneralInfo.where(is_district: 0, deleted: false).to_a
  end
  
  def insert_all_in_db(model, list_of_hashes)
    list_of_hashes = list_of_hashes.map{|hash| add_md5_hash(hash)}
    splits = list_of_hashes.each_slice(10000).to_a
    splits.each do |split|
      model.insert_all(split)
    end 
  end

  def add_md5_hash(hash)
    hash['run_id'] = @run_id
    hash['touched_run_id'] = @run_id
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end
end
  
