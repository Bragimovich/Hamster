# frozen_string_literal: true
require_relative '../lib/parser_helper'
class Parser < Hamster::Parser
  include ParserHelper

  def fetch_demographic_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[2])
    sub_group_hash  = get_sub_group_data
    data_array = []
    md5_hash   = []
    raw_data[3..].each do |row|
      data_array << get_demographic_data(row, headers, sub_group_hash["Total"], "Total", run_id, general_id_info)
      data_array << get_demographic_data(row, headers, sub_group_hash["Ethnicity"], "Ethnicity", run_id, general_id_info)
      data_array << get_demographic_data(row, headers, sub_group_hash["Gender"], "Gender", run_id, general_id_info)
      data_array << get_demographic_data(row, headers, sub_group_hash["Special Populations"], "Special Populations", run_id, general_id_info)
      data_array << get_demographic_data(row, headers, sub_group_hash["Grade"], "Grade", run_id, general_id_info)
    end
    data_array.flatten
  end

  def fetch_assessment_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_assessment_data(row, headers, run_id, general_id_info, "Mathematics")
      data_array << get_assessment_data(row, headers, run_id, general_id_info, "ELA")
      data_array << get_assessment_data(row, headers, run_id, general_id_info, "Science")
    end
    data_array
  end

  def fetch_dicipline_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    incidents_hash  = get_incidents_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_dicipline_data(row, headers, incidents_hash["Incidents"], run_id, general_id_info)
    end
    data_array.flatten
  end

  def fetch_financial_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[2])
    sub_group_hash  = get_financial_data_hash
    data_array = []
    raw_data[3..].each do |row|
      data_array << get_financial_data(row, headers, sub_group_hash, run_id, general_id_info)
    end
    data_array.flatten
  end

  def fetch_graduation_rate_data(file_path, year, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_graduation_data(row, headers, year, run_id, general_id_info)
    end
    data_array
  end

  def fetch_drop_out_rate_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_drop_out_rate_data(row, headers, grade_hash, run_id, general_id_info)
    end
    data_array.flatten
  end

  def fetch_crt_five_to_eight_dist_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Science", "CRT (Grades 5/8 Science)")
    end
    data_array.flatten
  end

  def fetch_crt_nine_to_ten_district_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_crt_nine_to_ten_district_data(row, headers, run_id, general_id_info)
    end
    data_array.flatten
  end

  def fetch_ccr_elven_district_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_ccr_elven_district_data(row, headers, run_id, general_id_info, "Mathematics")
      data_array << get_ccr_elven_district_data(row, headers, run_id, general_id_info, "ELA")
    end
    data_array.flatten
  end

  def fetch_naa_district_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_naa_district_data(row, headers, run_id, general_id_info, "Mathematics")
      data_array << get_naa_district_data(row, headers, run_id, general_id_info, "ELA")
      data_array << get_naa_district_data(row, headers, run_id, general_id_info, "Science")
    end
    data_array.flatten
  end

  def fetch_elpa_district_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_elpa_district_data(row, headers, run_id, general_id_info)
    end
    data_array.flatten
  end

  def fetch_crt_prior_district_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Mathematics", "CRT (Grades 3-8 ELA/Math 2014-15 and Prior)")
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Reading", "CRT (Grades 3-8 ELA/Math 2014-15 and Prior)")
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Science", "CRT (Grades 3-8 ELA/Math 2014-15 and Prior)")
    end
    data_array.flatten
  end

  def fetch_grade_prior_district_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Science", "Grade 10 Science (Old Standards 2015-16 and Prior)")
    end
    data_array.flatten
  end

  def fetch_writing_prior_district_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Writing", "Writing (Grades 5/8 2011-12 and Prior)")
    end
    data_array.flatten
  end

  def fetch_naa_prior_district_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Mathematics", "NAA (Grades 3-8 /11 ELA/Math/Science 2015-16 and Prior)")
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Reading", "NAA (Grades 3-8 /11 ELA/Math/Science 2015-16 and Prior)")
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Science", "NAA (Grades 3-8 /11 ELA/Math/Science 2015-16 and Prior)")
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Writing", "NAA (Grades 3-8 /11 ELA/Math/Science 2015-16 and Prior)")
    end
    data_array.flatten
  end

  def fetch_hspe_prior_district_data(file_path, run_id, general_id_info)
    raw_data        = read_csv(file_path)
    headers         = get_dynamic_index(raw_data[3])
    grade_hash      = get_grade_hash_data
    data_array = []
    raw_data[4..].each do |row|
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Mathematics", "HSPE (High School Math/Reading/Science/Writing 2014-15 and prior)")
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Reading", "HSPE (High School Math/Reading/Science/Writing 2014-15 and prior)")
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Science", "HSPE (High School Math/Reading/Science/Writing 2014-15 and prior)")
      data_array << get_common_dist_data(row, headers, run_id, general_id_info, "Writing", "HSPE (High School Math/Reading/Science/Writing 2014-15 and prior)")
    end
    data_array.flatten
  end

  private
 
  def get_demographic_data(data, headers, sub_group, group_str, run_id, general_id_info)
    data_array = []
    sub_group.each do |group|
      data_hash                   = {}
      organization_code           = data[headers["Organization Code"]]
      data_hash[:general_id]      = get_general_info_id(general_id_info, organization_code)
      data_hash[:school_year]     = data[headers["Accountability Year"]]
      data_hash[:subgroup]        = group_str
      data_hash[:demographic]     = group
      data_hash[:count]           = group == "Total Enrollment" ? data[headers["#{group}"]] : data[headers["#{group} #"]] rescue nil
      data_hash[:count]           = group == "EL (English Learners)"? data[headers["#{group.split("(").last[..-2]} #"]] : data_hash[:count]
      data_hash[:percent]         = group == "EL (English Learners)"? data[headers["#{group.split(" ").first} %"]] : data[headers["#{group} %"]] rescue nil
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_array << data_hash
    end
    data_array
  end

  def get_drop_out_rate_data(data, headers, grade_hash, run_id, general_id_info)
    data_array = []
    grade_hash["Grade"].each do |grade|
      data_hash                   = {}
      organization_code           = data[headers["Organization Code"]]
      data_hash[:general_id]      = get_general_info_id(general_id_info, organization_code)
      data_hash[:school_year]     = data[headers["Year"]]
      data_hash[:grade]           = grade
      data_hash[:dropout_rate]    = data[headers["#{grade} - Dropout Rate"]]
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_array << data_hash
    end
    data_array
  end

  def get_graduation_data(data, headers, year, run_id, general_id_info)
    data_hash                                 = {}
    organization_code                         = data[headers["Organization Code"]]
    data_hash[:general_id]                    = get_general_info_id(general_id_info, organization_code)
    data_hash[:school_year]                   = data[headers["Accountability Year"]]
    data_hash[:graduation_class]              = data[headers["Graduating Class of"]]
    data_hash[:graduation_type]               = "#{year} Years"
    data_hash[:total_students]                = data[headers["Total Students"]]
    data_hash[:total_graduates]               = data[headers["Total Graduates"]]
    data_hash[:graduation_rate]               = data[headers["Graduation Rate"]]
    data_hash[:total_adjusted_diploma]        = data[headers["Total Adjusted Diploma"]]
    data_hash[:total_adult_diploma]           = data[headers["Total Adult Diploma"]]
    data_hash[:total_advanced_diploma]        = data[headers["Total Advanced Diploma"]]
    data_hash[:certificates_of_attendance]    = data[headers["Certificates of Attendance"]]
    data_hash[:total_standart_diploma]        = data[headers["Total Standard Diploma"]]
    data_hash[:hse]                           = data[headers["HSE"]]
    data_hash[:total_alternative_diploma]     = data[headers["Total Alternative Diploma"]]
    data_hash[:total_college_career_diploma]  = data[headers["Total College and Career Ready Diploma"]]
    data_hash[:md5_hash]                      = create_md5_hash(data_hash)
    data_hash[:data_source_url]               = "http://nevadareportcard.nv.gov/di/main/cohort#{year}yr"
    data_hash[:run_id]                        = run_id
    data_hash[:touched_run_id]                = run_id
    data_hash
  end

  def get_financial_data(data, headers, sub_group, run_id, general_id_info)
    data_array = []
    sub_group["Fund"].each do |fund|
      sub_group["Type"].each do |type|
        sub_group["Spending Name"].each do |spending_name|
          data_hash                   = {}
          organization_code           = data[headers["Organization Code"]].squish
          data_hash[:general_id]      = get_general_info_id(general_id_info, organization_code)
          data_hash[:school_year]     = data[headers["Accountability Year"]]
          data_hash[:fund]            = fund
          data_hash[:type]            = type
          data_hash[:spending_name]   = spending_name
          short_fund                  = fund[0]
          short_fund = "SL"   if fund == "State/Local"
          ft_name                     = "#{short_fund} #{type[0]} #{spending_name.gsub(" ","")}"
          ft_name                     = "#{short_fund} NP #{spending_name.gsub(" ","")}" if type == "Non-Personnel"
          data_hash[:money]           = data[headers["#{ft_name}  $"]]
          data_hash[:percent]         = data[headers["#{ft_name} %"]]
          data_hash[:md5_hash]        = create_md5_hash(data_hash)
          data_hash[:run_id]          = run_id
          data_hash[:touched_run_id]  = run_id
          data_array << data_hash
        end
      end
      data_array << get_overall_spending(data, headers, fund, run_id)
    end
    data_array
  end

  def get_overall_spending(data, headers, fund, run_id)
    data_hash                   = {}
    data_hash[:general_id]      = nil
    data_hash[:school_year]     = data[headers["Accountability Year"]]
    data_hash[:fund]            = fund
    data_hash[:type]            = "Overall Spending"
    data_hash[:spending_name]   = "Total"
    short_fund                  = fund[0]
    short_fund = "SL"   if fund == "State/Local"
    data_hash[:money]           = data[headers["#{short_fund} Total  $"]]
    data_hash[:percent]         = data[headers["#{short_fund} Total %"]]
    data_hash[:md5_hash]        = create_md5_hash(data_hash)
    data_hash[:run_id]          = run_id
    data_hash[:touched_run_id]  = run_id
    data_hash
  end

  def get_dicipline_data(data, headers, sub_group, run_id, general_id_info)
    data_array = []
    sub_group.each do |group|
      data_hash                   = {}
      organization_code           = data[headers["Organization Code"]]
      data_hash[:general_id]      = get_general_info_id(general_id_info, organization_code)
      data_hash[:school_year]     = data[headers["Accountability Year"]]
      data_hash[:demographic]     = data[headers["Subgroup"]]
      data_hash[:incident]        = group
      data_hash[:number]          = data[headers[group]]
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_array << data_hash
    end
    data_array
  end

  def get_assessment_data(data, headers, run_id, general_id_info, subject)
    data_hash                           = {}
    organization_code                   = data[headers["Organization Code"]]
    data_hash[:general_id]              = get_general_info_id(general_id_info, organization_code)
    data_hash[:school_year]             = data[headers["Year"]]
    data_hash[:exam]                    = "CRT (Grades 3-8 ELA/Math)"
    data_hash[:subject]                 = subject
    data_hash[:number_enrollment]       = data[headers["Number Enrolled"]]
    data_hash[:number_tested]           = data[headers["#{subject} - Number Tested"]]
    data_hash[:not_tested_percent]      = data[headers["#{subject} - % Not Tested"]] rescue nil
    data_hash[:tested_percent] = subject == "ELA" ? data[headers["Reading - % Tested"]] :data[headers["#{subject} - % Tested"]] unless subject == "Science"
    data_hash[:tested_percent] = nil if subject == "Science"
    data_hash[:proficient_percent]      = data[headers["#{subject} - % Proficient"]]
    data_hash[:emergent_dev_percent]    = data[headers["#{subject} - % Emergent/Developing"]]
    data_hash[:approaches_percent]      = data[headers["#{subject} - % Approaches Standard"]]
    data_hash[:meets_percent]           = data[headers["#{subject} - % Meets Standard"]]
    data_hash[:exceeds_percent]         = data[headers["#{subject} - % Exceeds Standard"]]
    data_hash[:md5_hash]                = create_md5_hash(data_hash)
    data_hash[:run_id]                  = run_id
    data_hash[:touched_run_id]          = run_id
    data_hash
  end

  def get_naa_district_data(data, headers, run_id, general_id_info, subject)
    data_hash                        = {}
    organization_code                = data[headers["Organization Code"]]
    data_hash[:general_id]           = get_general_info_id(general_id_info, organization_code)
    data_hash[:school_year]          = data[headers["Year"]]
    data_hash[:exam]                 = "NAA (Grades 3-8 /11 ELA/Math/Science)"
    data_hash[:subject]              = subject
    data_hash[:number_enrollment]    = data[headers["Number Enrolled"]]
    data_hash[:number_tested]        = data[headers["#{subject} - Number Tested"]]
    data_hash[:not_tested_percent]   = data[headers["#{subject} -% Not Tested"]]
    data_hash[:tested_percent]       = data[headers["#{subject} -% Tested"]]
    data_hash[:proficient_percent]   = data[headers["#{subject} - % Proficient"]]
    data_hash[:emergent_dev_percent] = data[headers["#{subject} - % Emergent/Developing"]]
    data_hash[:approaches_percent]   = data[headers["#{subject} - % Approaches Standard"]]
    data_hash[:meets_percent]        = data[headers["#{subject} - % Meets Standard"]]
    data_hash[:exceeds_percent]      = data[headers["#{subject} - % Exceeds Standard"]]
    data_hash[:md5_hash]             = create_md5_hash(data_hash)
    data_hash[:run_id]               = run_id
    data_hash[:touched_run_id]       = run_id
    data_hash
  end

  def get_crt_nine_to_ten_district_data(data, headers, run_id, general_id_info)
    data_hash                        = {}
    organization_code                = data[headers["Organization Code"]]
    data_hash[:general_id]           = get_general_info_id(general_id_info, organization_code)
    data_hash[:school_year]          = data[headers["Year"]]
    data_hash[:exam]                 = "CRT (Grades 9/10 Science)"
    data_hash[:subject]              = "Science"
    data_hash[:number_enrollment]    = data[headers["Number Enrolled"]]
    data_hash[:number_tested]        = data[headers["Number Tested"]]
    data_hash[:not_tested_percent]   = data[headers["Science - % Not Tested"]]
    data_hash[:tested_percent]       = data[headers["Science - % Tested"]]
    data_hash[:proficient_percent]   = data[headers["% Proficient"]]
    data_hash[:emergent_dev_percent] = nil
    data_hash[:approaches_percent]   = nil
    data_hash[:meets_percent]        = nil
    data_hash[:exceeds_percent]      = nil
    data_hash[:md5_hash]             = create_md5_hash(data_hash)
    data_hash[:run_id]               = run_id
    data_hash[:touched_run_id]       = run_id
    data_hash
  end

  def get_common_dist_data(data, headers, run_id, general_id_info, subject, exam)
    data_hash                        = {}
    organization_code                = data[headers["Organization Code"]]
    data_hash[:general_id]           = get_general_info_id(general_id_info, organization_code)
    data_hash[:school_year]          = data[headers["Year"]]
    data_hash[:exam]                 = exam
    data_hash[:subject]              = subject
    data_hash[:number_enrollment]    = data[headers["Number Enrolled"]]
    data_hash[:number_tested]        = data[headers["#{subject} - Number Tested"]]
    data_hash[:not_tested_percent]   = data[headers["#{subject} - % Not Tested"]] rescue nil
    data_hash[:tested_percent]       = data[headers["#{subject} - % Tested"]] rescue nil
    data_hash[:proficient_percent]   = data[headers["#{subject} - % Proficient"]]
    data_hash[:emergent_dev_percent] = data[headers["#{subject} - % Emergent/Developing"]]
    data_hash[:approaches_percent]   = data[headers["#{subject} - % Approaches Standard"]]
    data_hash[:meets_percent]        = data[headers["#{subject} - % Meets Standard"]]
    data_hash[:exceeds_percent]      = data[headers["#{subject} - % Exceeds Standard"]]
    data_hash[:md5_hash]             = create_md5_hash(data_hash)
    data_hash[:run_id]               = run_id
    data_hash[:touched_run_id]       = run_id
    data_hash
  end

  def get_ccr_elven_district_data(data, headers, run_id, general_id_info, subject)
    data_hash                           = {}
    organization_code                   = data[headers["Organization Code"]]
    data_hash[:general_id]              = get_general_info_id(general_id_info, organization_code)
    data_hash[:school_year]             = data[headers["Year"]]
    data_hash[:exam]                    = "CCR (Grade 11 High School ELA/Math)"
    data_hash[:subject]                 = subject
    data_hash[:number_enrollment]       = data[headers["Number Enrolled"]]
    data_hash[:number_tested]           = data[headers["#{subject} - Number Tested"]]
    data_hash[:not_tested_percent]      = data[headers["#{subject} - % Not Tested"]]
    data_hash[:tested_percent] = subject == "ELA" ? data[headers["English - % Tested"]] :data[headers["#{subject} - % Tested"]]
    data_hash[:proficient_percent]      = data[headers["#{subject} - % Proficient"]]
    data_hash[:emergent_dev_percent]    = data[headers["#{subject} - % Emergent/Developing"]]
    data_hash[:approaches_percent]      = data[headers["#{subject} - % Approaches Standard"]]
    data_hash[:meets_percent]           = data[headers["#{subject} - % Meets Standard"]]
    data_hash[:exceeds_percent]         = data[headers["#{subject} - % Exceeds Standard"]]
    data_hash[:md5_hash]                = create_md5_hash(data_hash)
    data_hash[:run_id]                  = run_id
    data_hash[:touched_run_id]          = run_id
    data_hash
  end

  def get_elpa_district_data(data, headers, run_id, general_id_info)
    data_hash                        = {}
    organization_code                = data[headers["Organization Code"]]
    data_hash[:general_id]           = get_general_info_id(general_id_info, organization_code)
    data_hash[:school_year]          = data[headers["Year"]]
    data_hash[:exam]                 = "ELPA"
    data_hash[:subject]              = nil
    data_hash[:approaches_percent]   = nil
    data_hash[:meets_percent]        = nil
    data_hash[:exceeds_percent]      = nil
    data_hash[:number_enrollment]    = data[headers["Number Enrolled"]]
    data_hash[:number_tested]        = data[headers["Number Tested"]]
    data_hash[:not_tested_percent]   = data[headers["% Not Tested"]]
    data_hash[:tested_percent]       = data[headers["% Tested"]]
    data_hash[:proficient_percent]   = data[headers["% Proficient"]]
    data_hash[:emergent_dev_percent] = data[headers["%  Emerging"]]
    data_hash[:md5_hash]             = create_md5_hash(data_hash)
    data_hash[:run_id]               = run_id
    data_hash[:touched_run_id]       = run_id
    data_hash    
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
