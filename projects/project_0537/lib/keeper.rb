require_relative '../models/in_general_info'
require_relative '../models/in_administrators'
require_relative '../models/in_enrollment_by_ethnicity'
require_relative '../models/in_enrollment_by_grade'
require_relative '../models/in_enrollment_by_meal_status'
require_relative '../models/in_enrollment_by_special_edu_and_ell'
require_relative '../models/in_schools_assessment'
require_relative '../models/in_schools_assessment_by_levels'
require_relative '../models/in_schools_sat'
require_relative '../models/in_runs'

class Keeper

  def initialize
    @run_object = RunId.new(InRuns)
    @run_id = @run_object.run_id
  end
  #
  def get_global_id(id)
    check = InGeneralInfo.where(number: id).select(:id).first
    if check then check.id end
  end

  def get_assessment_id(data)
    check = InSchoolsAssessment.where(data).select(:id).first
    if check then check.id end
  end

  # =========== GENERAL SECTION ===========
  def save_on_general_info(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    InGeneralInfo.insert(data)
  end

  def save_on_administrators(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    InAdministrators.insert(data)
  end

  def get_district_id(corp_id)
    check = InGeneralInfo.where(number: corp_id, is_district: 1).select(:id).first
    if check then check.id end
  end

  def get_id(data)
    check = InGeneralInfo.where(name: data).select(:id).first
    if check then check.id end
  end

  def existed_data_general_table(data)
    InGeneralInfo.where(data).first
  end

  def existed_data_administrators_table(data)
    InAdministrators.where(data).first
  end

  # ===== ENROLLMENT SECTION =====

  # Save data to in_enrollment_by_grade table
  def save_on_in_enrollment_by_grade(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    InEnrollmentByGrade.insert(data)
  end

  def existed_data_enrollment_by_grade_table(data)
    InEnrollmentByGrade.where(data).first
  end

  def save_on_in_enrollment_by_ethnicity(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    InEnrollmentByEthnicity.insert(data)
  end

  def save_on_in_enrollment_by_meal_status(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    InEnrollmentByMealStatus.insert(data)
  end

  def existed_data_enrollment_by_ethnicity(data)
    InEnrollmentByEthnicity.where(data).first
  end

  def existed_data_enrollment_by_meal_status(data)
    InEnrollmentByMealStatus.where(data).first
  end

  # Save data to in_enrollment_by_special_edu_and_ell table
  def save_on_in_enrollment_by_special_edu_and_ell(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    InEnrollmentBySpecialEduAndEll.insert(data)
  end

  def existed_data_enrollment_by_special_edu_and_ell(data)
    InEnrollmentBySpecialEduAndEll.where(data).first
  end

  # ===== ASSESSMENT SECTION =====

  def save_on_in_schools_assessment(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    InSchoolsAssessment.insert(data)
  end

  def save_on_in_schools_assessment_by_levels(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    InSchoolsAssessmentByLevels.insert(data)
  end

  def existed_data_in_schools_assessment(data)
    InSchoolsAssessment.where(data).first
  end

  def existed_data_in_schools_assessment_by_levels(data)
    InSchoolsAssessmentByLevels.where(data).first
  end

  # ===== SAT SECTION =====

  def save_on_in_schools_sat(data)
    data.merge!(run_id: @run_id,touched_run_id: @run_id)
    InSchoolsSat.insert(data)
  end

  def existed_data_in_schools_sat(data)
    InSchoolsSat.where(data).first
  end

  def finish
    @run_object.finish
  end


end