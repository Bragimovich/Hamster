# OLD
# ga_general_info
# ga_enrollment
# ga_assessment_national
# ga_schools_assessment
# ga_schools_assessment_by_levels
# ga_assessment_act
# ga_graduation_rate
# ga_administrators
# ga_safety_audit
# ga_safety_audit_measures
# ga_safety_events
# ga_safety_climate
# ga_safety_climate_index
# ga_runs

# NEW
# ga_general_info
# ga_enrollment_by_grade
# ga_enrollment_by_subgroup
# ga_assessment_eoc_by_subgroup
# ga_assessment_eoc_by_grade
# ga_assessment_eog_by_subgroup
# ga_assessment_eog_by_grade
# ga_graduation_4_year_cohort
# ga_graduation_5_year_cohort
# ga_graduation_hope
# ga_revenue_expenditure
# ga_salaries_benefits
# ga_runs

require_relative '../models/us_district'
require_relative '../models/us_school'
require_relative '../models/ga_runs'
require_relative '../models/ga_general_info'
require_relative '../models/ga_enrollment_by_grade'
require_relative '../models/ga_enrollment_by_subgroup'
require_relative '../models/ga_assessment_eoc_by_subgroup'
require_relative '../models/ga_assessment_eoc_by_grade'
require_relative '../models/ga_assessment_eog_by_subgroup'
require_relative '../models/ga_assessment_eog_by_grade'
require_relative '../models/ga_graduation_4_year_cohort'
require_relative '../models/ga_graduation_5_year_cohort'
require_relative '../models/ga_graduation_hope'
require_relative '../models/ga_revenue_expenditure'
require_relative '../models/ga_salaries_benefits'

class Keeper < Hamster::Harvester

  def initialize
    super
    @run_object = RunId.new(GaRuns)
    @run_id = @run_object.run_id
  end

  def sync_general_info_table
    state_hash = {
        is_district: 0,
        district_id: nil,
        name: "State",
        data_source_url: 'https://download.gosa.ga.gov/'
    }
    store_general_info(state_hash)
    ga_districts = UsDistrict.where(state: "GA").as_json(only: [:number, :name, :nces_id,:type,:phone, :address,:city, :state, :zip, :zip_4, :data_source_url])
    ga_districts.each do |hash|
      hash[:is_district] = 1
      store_general_info(hash)
    end
    ga_schools = UsSchool.where(state: "GA").as_json(only: [:district_number, :number, :name, :low_grade, :high_grade, :charter, :magnet, :title_1_school, :title_1_school_wide, :nces_id, :type, :phone, :address, :city, :state, :zip, :zip_4, :data_source_url])
    ga_schools.each do |hash|
      hash[:is_district] = 0
      hash[:district_id] = GaGeneralInfo.where(is_district: 1, number: hash["district_number"])&.first&.id
      hash.delete("district_number")
      store_general_info(hash)
    end
  end

  def store_general_info(hash)
    hash = add_md5_hash(hash)
    hash = HashWithIndifferentAccess.new(hash)
    check = GaGeneralInfo.where(md5_hash: hash['md5_hash'], deleted: 0).as_json.first
    if check
      GaGeneralInfo.update(check['id'], {touched_run_id: @run_id})
    else
      GaGeneralInfo.insert(hash.merge({run_id: @run_id, touched_run_id: @run_id}))
    end
  end

  def store_ga_district(district)
    GaGeneralInfo.store_district(district, @run_id)
  end

  def store_ga_school(school, district_id, record_from_file)
    GaGeneralInfo.store_school(school, district_id, record_from_file, @run_id)
  end

  def get_general_info_id(record)
    GaGeneralInfo.get_id(record)
  end

  def store_ga_enrollment_by_grade(ga_enrollment_by_grade)
    GaEnrollmentByGrade.store(ga_enrollment_by_grade, @run_id)
  end

  def store_ga_enrollment_by_subgroup(ga_enrollment_by_subgroup)
    GaEnrollmentBySubgroup.store(ga_enrollment_by_subgroup, @run_id)
  end

  def store_ga_assessment_eoc_by_grade(ga_assessment_eoc_by_grade)
    GaAssessmentEocByGrade.store(ga_assessment_eoc_by_grade, @run_id)
  end

  def store_ga_assessment_eoc_by_subgroup(ga_assessment_eoc_by_subgroup)
    GaAssessmentEocBySubgroup.store(ga_assessment_eoc_by_subgroup, @run_id)
  end

  def store_ga_assessment_eog_by_grade(ga_assessment_eog_by_grade)
    GaAssessmentEogByGrade.store(ga_assessment_eog_by_grade, @run_id)
  end

  def store_ga_assessment_eog_by_subgroup(ga_assessment_eog_by_subgroup)
    GaAssessmentEogBySubgroup.store(ga_assessment_eog_by_subgroup, @run_id)
  end

  def store_ga_graduation_4_year_cohort(ga_graduation_4_year_cohort)
    GaGraduation4YearCohort.store(ga_graduation_4_year_cohort, @run_id)
  end

  def store_ga_graduation_5_year_cohort(ga_graduation_5_year_cohort)
    GaGraduation5YearCohort.store(ga_graduation_5_year_cohort, @run_id)
  end

  def store_ga_revenue_expenditure(ga_revenue_expenditure)
    GaRevenueExpenditure.store(ga_revenue_expenditure, @run_id)
  end

  def store_ga_salaries_benefits(ga_salaries_benefits)
    GaSalariesBenefits.store(ga_salaries_benefits, @run_id)
  end

  def store_ga_graduation_hope(ga_graduation_hope)
    GaGraduationHope.store(ga_graduation_hope, @run_id)
  end
  
  def finish
    @run_object.finish
  end

  def add_md5_hash(hash)
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end
  
end