require 'roo'
require 'roo-xls'

require_relative './modules/general_info'
require_relative './modules/enrollment_data'
require_relative './modules/ilearn'
require_relative './modules/istep'
require_relative './modules/i_am'
require_relative './modules/iread'
require_relative './modules/sat'

class Parser < Hamster::Parser

  # Method to get the year from Stirng
  def get_year(file_name)
    year = file_name.gsub('_', '-').scan(/\b\d{4}\b/).map(&:to_i)
    return "#{year[0]-1}-#{year[0]}"
  end

  # Method to get a sequence of numbers for parser line
  def get_range(start, index, quantity, space)
    (start + (index * (quantity + space))..start + (index * (quantity + space)) + quantity - 1)
  end

  # Save data to in_general_info and in_administrators tables
  def get_genaral_info(arr_files)
    parser_genaral_info(arr_files)
  end

  # ===== ENROLLMENT SECTION =====
  # Save data to in_enrollment_by_grade table
  def get_enrollment_grade_info(arr_files)
    parser_enrollment_grade_info(arr_files)
  end

  # Save data to in_enrollment_by_ethnicity and in_enrollment_by_meal_status tables
  def get_enrollment_ethnicity(arr_files)
    parser_enrollment_ethnicity(arr_files)
  end

  # Save data to in_enrollment_by_special_edu_and_ell table
  def get_enrollment_by_special_edu_and_ell(arr_files)
    parser_enrollment_by_special_edu_and_ell(arr_files)
  end

  # ===== ASSESSMENT SECTION =====
  # ======= ILEARN =======
  # Save data to in_schools_assessment and in_schools_assessment_by_levels tables
  def get_assessment_ilearn_info(arr_files)
    parser_assessment_ilearn_info(arr_files)
  end


  # ======= ISTEP+ =======
  # Save data to in_schools_assessment table
  def get_assessment_istep_plus(arr_files)
    parser_assessment_istep_plus(arr_files)
  end

  # ======= I AM  Alternate =======
  # Save data to in_schools_assessment and in_schools_assessment_by_levels tables
  def get_i_am_alternate(arr_files)
    parser_i_am_alternate(arr_files)
  end

  # ======= IREAD-3 =======
  # Save data to in_schools_assessment and in_schools_assessment_by_levels tables
  def get_iread_3(arr_files)
    parser_iread_3(arr_files)
  end

  # ======= SAT =======
  # Save data to in_schools_sat table
  def get_sat(arr_files)
    parser_sat(arr_files)
  end

end

