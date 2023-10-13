require_relative '../models/de_general_info'
require_relative '../models/de_general_info_run'
require_relative '../models/de_salary'
require_relative '../models/de_growth'
require_relative '../models/us_districts'
require_relative '../models/us_schools'
require_relative '../models/de_assessment'
require_relative '../models/de_discipline'
require_relative '../models/de_graduation'
require_relative '../models/de_enrollment'

class Keeper
  attr_accessor :run_id

  def initialize
    @run_object = RunId.new(DeGeneralInfoRuns)
    @run_id = @run_object.run_id
  end

  def store_data(data_hash, model)
    data_hash = data_hash.map {|hash| add_run_id(hash)}
    data_hash = add_general_id(data_hash)
    data_hash = filter_data(data_hash)
    model.insert_all(data_hash)
  end

  def store_general_info
    null_record = {name: "State of Delaware", number: '0'}
    null_record = add_run_id(null_record)
    generate_md5_hash(%i[is_district name], null_record)
    DeGeneralInfo.insert(null_record)

    us_district = UsDistricts.where(state:'DE')
    district_array = us_district.to_a.map(&:serializable_hash).map{|hash| hash.transform_keys(&:to_sym)}
    general_info_district_id = district_array.each {|district| district[:district_id] = district[:id]}
    general_info_district_id = general_info_district_id.map {|district| district.slice(:district_id, :number, :name, :county, :type, :low_grade, :high_grade, :charter, :magnet, :title_1_school, :title_1_school_wide, :nces_id, :phone,:address, :city, :state, :zip, :zip_4, :md5_hash)}

    general_info_district_id = general_info_district_id.map {|hash| add_run_id(hash)}
    general_info_district_id = general_info_district_id.map {|hash| hash.merge({is_district:1})}
    DeGeneralInfo.insert_all(general_info_district_id)

    us_school = UsSchools.where(state:'DE')
    school_array = us_school.to_a.map(&:serializable_hash).map{|hash| hash.transform_keys(&:to_sym)}
    general_info_school = school_array.map {|district| district.slice(:is_district, :number, :county, :name, :type, :low_grade, :high_grade, :charter, :magnet, :title_1_school, :title_1_school_wide, :nces_id, :phone, :address, :city, :state, :zip, :zip_4, :md5_hash)}
    general_info_school = general_info_school.map {|hash| hash.merge({is_district:0})}
    general_info_school = general_info_school.map {|hash| add_run_id(hash)}
    general_info_school = general_info_school.map {|hash| hash.merge({district_id: DeGeneralInfo.select('id').where(is_district: 1, number: hash['number'])})}
    DeGeneralInfo.insert_all(general_info_school)
  end

  def get_general_id
    DeGeneralInfo.pluck(:id, :number).map {|id, number| {id: id, number: number}}
  end

  def filter_data(data_hash)
    final_data = data_hash.each do |hash|
      hash.delete(:name)
      hash.delete(:is_district)
      hash.delete(:number)
    end
    final_data
  end

  def add_general_id(data_hash)
    add_number_general = data_hash.each {|hash| hash[:general_id] == nil}
    add_number_general_info = add_number_general.map {|hash| hash.slice(:number, :is_district, :name, :run_id, :touched_run_id)}.compact
    add_number_general_info = add_number_general_info.each do |hash|
      generate_md5_hash(%i[number is_district name], hash)
    end

    add_number_general_info = add_number_general_info.select {|hash| hash[:number] != '0'}
    uniq_data_number = []
    array_number = DeGeneralInfo.pluck(:number)
    add_number_general_info.each do |num|
      unless array_number.include?(num[:number])
        uniq_data_number << num
      end
    end

    if uniq_data_number.present?
      DeGeneralInfo.insert_all(uniq_data_number)
    end
    data_hash = data_hash.each do |hash|
      unless hash[:general_id].present?
        hash[:general_id] = get_general_id.select {|general| general[:number] == hash[:number]}[0][:id]
      end
    end
    data_hash
  end

  def add_run_id(hash)
    hash[:run_id] = @run_id
    hash[:touched_run_id] = @run_id
    hash
  end

  def generate_md5_hash(column, hash)
    md5 = MD5Hash.new(columns: column)
    md5.generate(hash)
    hash[:md5_hash] = md5.hash
  end

  def finish
    @run_object.finish
  end
end
