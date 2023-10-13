# require_relative '../models/wisconsin_government_employees_salaries'
require_relative '../models/fl_hurricane_insurance_runs'
require_relative '../models/fl_hurricane_insurance__business_categories'
require_relative '../models/fl_hurricane_insurance__data_categories'
require_relative '../models/fl_hurricane_insurance_hurricanes'
require_relative '../models/fl_hurricane_insurance_state_data'
require_relative '../models/fl_hurricane_insurance_counties'
require_relative '../models/fl_hurricane_insurance_county_data'

class Keeper

  def initialize
    @run_object = RunId.new(FLhurricaneInsuranceRuns)
    @run_id = @run_object.run_id
  end

  DB_MODELS = {
    'InsuranceStateData': InsuranceStateData,
    'InsuranceCounties': InsuranceCounties,
    'InsuranceCountyData': InsuranceCountyData,
    'business_categories': BusinessCategories,
    'hurricanes': Hurricanes,
    'DataCategories': DataCategories
  }

  attr_reader :run_id

  def fetch_businesses(key)
    DB_MODELS[:"#{key}"].pluck(:id, :categ_code, :categ_desc, :is_parent)
  end

  def insert_records(key, data_array)
    DB_MODELS[:"#{key}"].insert_all(data_array) unless data_array.empty?
  end

  def businessCategories_Ids
    BusinessCategories.pluck(:categ_code, :categ_desc, :child_categ_code)
  end

  def hurricanes_fetchId(key)
    DB_MODELS[:"#{key}"].pluck(:id, :hurricane_name)
  end

  def insuranceCounties_fetchId(key)
    DB_MODELS[:"#{key}"].pluck(:id, :county_name)
  end

  def dataCategories_fetchId(key)
    DB_MODELS[:"#{key}"].pluck(:id, :categ_desc)
  end

  def insert_business_category(key, data_hash, is_parent)
    DB_MODELS[:"#{key}"].insert(data_hash)
  end

  def fetch_parent_id(key, parent_name)
    parent_id = DB_MODELS[:"#{key}"].where(categ_desc: parent_name).pluck(:categ_code).first
    child_id = DB_MODELS[:"#{key}"].all.select{|e| e[:categ_code].include? parent_id}.last[:categ_code] rescue []
    (child_id.empty?) ? parent_id : child_id
  end

  def parent_record_exists?(key, parent_name, is_parent)
    DB_MODELS[:"#{key}"].where(categ_desc: parent_name, is_parent: is_parent).count
  end

  def fetch_hurricane_id(key, hurricane_name)
    DB_MODELS[:"#{key}"].where(hurricane_name: hurricane_name).pluck(:id).first
  end

  def finish
    @run_object.finish
  end
end
