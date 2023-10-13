# frozen_string_literal: true

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

class  Keeper < Hamster::Harvester
  attr_writer   :general_id, :sch_cd, :school_year
  def initialize
    @run_id = 1
    #@id = KySchoolsAssessment.select(:id).pluck(:id).last || 0 #for assessment
    @main_arr = []
    @assessment_lvl = []
    @source_url = "https://openhouse.education.ky.gov/Home/SRCData"
    @arr = []
  end

  def district(row)
      district = (row['SCHOOL CODE'] || row['SCH_CD'])
      school = KyGeneralInfo.find_by(school_code: district)
      if district.size < 6
        number = (row['DISTRICT NUMBER'] || row['DIST_NUMBER']) || district
        name = row['DIST_NAME'] || row['DISTRICT NAME'] rescue nil
        district = true
      else
        number = (row['SCHOOL NUMBER'] || row['SCH_NUMBER']) || district.split('').last(3).join
        name = row['SCHOOL NAME'] || row['SCH_NAME'] rescue nil
        district = false
      end
      hash = {
        county_number: row['COUNTY NUMBER'] || row['CNTYNO'],
        is_district: district,
        number: number,
        name: name,
        school_code: row['SCH_CD'] || row['SCHOOL CODE'],
        state_school_id: row['STATE SCHOOL ID'] || row['STATE_SCH_ID'],
        nces_id: row['NCES_CD'] || row['NCES ID'] || row['NCESID'],
        coop_code: row['CO-OP CODE']  || row['COOP_CODE'],
        coop_name: row['CO-OP'] || row['COOP'],
        school_type: row['SCH_TYPE'] || row['SCHOOL TYPE'],
        low_grade: row['LOW_GRADE'] || row['LOW GRADE'],
        high_grade: row['HIGH_GRADE'] || row['HIGH GRADE'],
        title_1_status: row['TITLE1_STATUS'] || row['TITLE I STATUS'],
        program_type: '',
        education_program: '',
        locale: '',
        phone: row['PHONE'],
        fax: row['FAX'],
        website: '',
        address: row['ADDRESS'],
        city: row['CITY'],
        county: row['COUNTY NAME'] || row['CNTYNAME'],
        state: row['STATE'],
        zip: row['ZIPCODE'],
        lat: row['LATITUDE'],
        lon: row['LONGITUDE']
      }
    if school.nil?
      hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
      @main_arr  << hash
    else
      school.update(touched_run_id: @run_id)
    end
  end

  def administrators(row)
    school = KyGeneralInfo.find_by(school_code: row['SCH_CD'] || row['SCHOOL CODE'])
    school.is_district == true ? role = 'Superintendent' : role = 'Principal' rescue nil
    hash = {
      general_id: school.id,
      role: role,
      full_name: row['CONTACT NAME'] || row['CONTACT_NAME'],
      school_year: @school_year
      }
    hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
    @main_arr  << hash
  end
 
  def enrollment(row)
    get_district_id(row)
    demographics = ["Male", "Female", "White", "Black", "Hispanic", "Asian", "Aian", "Hawaiian", "Other", "Free_Lunch", "Reduced_Lunch"]
    total_h = {
      general_id: @general_id,
      school_year: @school_year,
      demographic: 'Total',
      grade: 'Total',
      count:  row['MEMBERSHIP_TOTAL'] || row['ENROLLMENT_TOTAL'],
      percent: nil,
      dropout_rate: row['DROPOUT_RATE']
    }
    total_h.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(total_h))
    @main_arr << total_h

    demographics.each do |grade|
      hash = {
        general_id: @general_id,
        school_year: @school_year,
        grade: 'Total',
        demographic: grade.split('_').join(' '),
        count:  row["MEMBERSHIP_#{grade.upcase}_CNT"] || row["ENROLLMENT_#{grade.upcase}_CNT"],
        percent: row["MEMBERSHIP_#{grade.upcase}_PCT"] || row["ENROLLMENT_#{grade.upcase}_PCT"],
        dropout_rate: nil
      }
      hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
      @main_arr  << hash
    end
  end

  def enrollment_new(row)
    get_district_id(row)
    grades = ['TOTALSTUDENTS', 'P_CNT', 'K_CNT', 'G1_CNT', 'G2_CNT', 'G3_CNT', 'G4_CNT', 'G5_CNT', 'G6_CNT', 'G7_CNT', 'G8_CNT', 'G9_CNT', 'G10_CNT', 'G11_CNT', 'G12_CNT', 'G14_CNT']
    grades.each do |grade|
      hash = {
        general_id: @general_id,
        school_year: @school_year,
        grade: grade,
        demographic: row['STUDENTGROUP'],
        count:  row[grade]
      }
      hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
      @main_arr  << hash
    end
  end

  def enrollment_csv(row)
    get_district_id(row)
    grades = ['TOTAL STUDENT COUNT', 'PRESCHOOL COUNT', 'KINDERGARTEN COUNT',	'GRADE1 COUNT', 'GRADE2 COUNT', 'GRADE3 COUNT', 'GRADE4 COUNT', 'GRADE5 COUNT', 'GRADE6 COUNT', 'GRADE7 COUNT', 'GRADE8 COUNT', 'GRADE9 COUNT', 'GRADE10 COUNT', 'GRADE11 COUNT', 'GRADE12 COUNT', 'GRADE14 COUNT']
    grades.each do |grade|
      hash = {
        general_id: @general_id,
        school_year: @school_year,
        grade: grade,
        demographic: row['DEMOGRAPHIC'],
        count:  row[grade]
      }
      hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
      @main_arr  << hash
    end
  end

  def dropout_csv(row)
    get_district_id(row)
    dropout_update = KyEnrollment.find_by(general_id: @general_id, demographic: row['DEMOGRAPHIC'], school_year: @school_year, grade: 'TOTAL STUDENT COUNT' ).update(suppressed: row['SUPPRESSED'], dropout_rate: row['DROPOUTRATE'] || row['DROPOUT RATE'], dropout_count: row['DROPOUTCNT'] || row['DROPOUT COUNT'], dropout_membership: row['DROPOUTMEM'] || row['DROUPOUT MEMBERSHIP'] ) rescue nil
    if dropout_update.nil?
      @arr << row
    end
  end

  def dropout(row)
    get_district_id(row)
    en_demographics = ['ETB', 'TST', 'ETA', 'CSG', 'LEP', 'SXF', 'FOS', 'LUP', 'GTR', 'ETP', 'ETH', 'HOM', 'ETI', 'SXM', 'MIG', 'MIL', 'ACD', 'ETO', 'ETW']
    dr_demographics = ['African American', 'All Students', 'Asian', 'Consolidated Student Group', 'EL', 'Female', 'Foster', 'Free/Reduced', 'Gifted & Talented', 'Hawaiian/PI', 'Hispanic', 'Homeless', 'Indian/Alaska', 'Male', 'Migrant', 'MilitaryConnected' 'Studw/disab.', 'Two or More', 'White']
    value = en_demographics.index(row['DEMOGRAPHIC']) rescue nil
    unless value.nil?
      dropout_update = KyEnrollment.find_by(general_id: @general_id, demographic: dr_demographics[value], school_year: @school_year, grade: 'TOTALSTUDENTS' ).update(suppressed: row['SUPPRESSED'], dropout_rate: row['DROPOUTRATE'], dropout_count: row['DROPOUTCNT'], dropout_membership: row['DROPOUTMEM'] ) rescue nil
      if dropout_update.nil?
        @arr << row
      end
    end
  end

  def assessment(row)
    get_district_id(row)
    hash = {
      general_id:  @general_id,
      school_year: @school_year,
      exam_name: "Kentucky Summative Assessments",
      grade: row["GRADE_LEVEL"] || row['GRADE'] || row['GRADE	LEVEL'],
      subject: row["CONTENT_TYPE"] || row['SUBJECT'],
      demographic: row["DISAGG_LABEL"] || row['DEMOGRAPHIC'],
      number_tested: row["NBR_TESTED"] || row['TESTED'] || row['PARTICIPATION POPULATION']
    }
    hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
    @main_arr  << hash
    id = @id += 1
    #col_name = ["PCT_NOVICE", "PCT_APPRENTICE", "PCT_PROFICIENT", "PCT_DISTINGUISHED", "PCT_PROFICIENT_DISTINGUISHED"]
    #col_name = ['NOVICE', 'APPRENTICE', 'PROFICIENT', 'distinguished', 'PROFICIENT_DISTINGUISHED']
    col_name = ['NOVICE', 'APPRENTICE', 'PROFICIENT', 'DISTINGUISHED', 'PROFICIENT/DISTINGUISHED']
    col_name.each_with_index do |value, index|
      h = {
        assessment_id: id,
        level: col_name[index],
        percent: row[value]
      }
      h.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(h))
      @assessment_lvl << h
    end
  end

  def assessment_act(row)
    get_district_id(row)
    name = ['ENGLISH', 'MATHEMATICS', 'READING', 'SCIENCE', 'COMPOSITE']
    #mean_score = ['ENGLISH_MEAN_SCORE', 'MATHEMATICS_MEAN_SCORE', 'READING_MEAN_SCORE', 'SCIENCE_MEAN_SCORE', 'COMPOSITE_MEAN_SCORE']
    #benchmarks = ['ENGLISH_BNCHMRK_PCT', 'MATHEMATICS_BNCHMRK_PCT', 'READING_BNCHMRK_PCT']
    #mean_score = ['AVG_ENG', 'AVG_RD', 'AVG_MA', 'AVG_SC', 'AVG_COMP']
    #benchmarks = ['ENG_BENCH', 'RD_BENCH', 'MA_BENCH']

    mean_score = ['Average ACT Scores: English', 'Average ACT Scores: Reading', 'Average ACT Scores: Math', ' Average ACT Scores: Science', 'Average ACT Composite Score']
    benchmarks = ['Number of Students Meeting Benchmarks: English	', 'Number of Students Meeting Benchmarks: Reading', 'Number of Students Meeting Benchmarks: Math']
    mean_score.each_with_index do |value, index|
      hash = {
        general_id: @general_id,
        school_year: @school_year,
        subject: name[index],
        demographic: row["DISAGG_LABEL"] || row['DEMOGRAPHIC'],
        suppressed_average: row['SUPPRESSEDAVG'] || row['Suppressed Average Score'],
        suppressed_benchmarks: row['SUPPRESSEDBENCH'] || row['Suppressed Benchmark Scores'],
        tested_count: row['STDNT_TESTED_CNT'] || row['TESTED'] || row['Number of Students Tested Average Scores'],
        average_act_scores: row[mean_score[index]],
        percent_meeting_benchmarks: row[benchmarks[index]]
      }
      hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
      @main_arr  << hash
    end
  end

  def assesment_national(row)
    hash = {
      school_year: @school_year,
      grade: row['GRADE'],
      subject: row['CONTENT_TYPE'] || row['SUBJECT'],
      demographic: row['DISAGG_LABEL'] || row['DEMOGRAPHIC'],
      level: row['ASSESSMENT_LEVEL'] || row['LEVEL'],
      percent_below_basic_level: row['BELOW_BASIC'] || row['BELOWBASIC'] || row['PERCENT OF STUDENTS BELOW BASIC LEVEL'],
      percent_at_basic_level: row['AT_BASIC'] || row['ATBASIC'] || row['PERCENT OF STUDENTS AT BASIC LEVEL'],
      percent_procient: row['AT_PROFICIENT'] || row['ATPROFICIENT'] || row['PERCENT PROFICIENT'],
      percent_at_advanced_level: row['AT_ADVANCED'] || row['ATADVANCED'] || row['PERCENT OF STUDENTS AT ADVANCED LEVEL'],
      parcipation_rate: row['PARTICIPATION_RATE'] || row['PARTICIPATIONRATE'] || row['PARTICIPATION RATE']
    }
    hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
    @main_arr  << hash
  end

  def graduation_rate(row)
    get_district_id(row)
    hash = {
      general_id: @general_id,
      graduation_type: '4-YEAR',#row['COHORT_TYPE'],#'4-YEAR' for 2012-2013
      suppressed: row['SUPPRESSED4YR'] || row['SUPPRESSED 4 YEAR'],
      school_year: @school_year,
      demographic: row["DISAGG_LABEL"] || row['DEMOGRAPHIC'],
      number_of_grads: row['COHORT_NUMERATOR'] || row['GRADS4YR'] || row['NUMBER OF GRADS IN 4-YEAR COHORT'],
      number_of_students: row['COHORT_DENOMINATOR'] || row['COHORT4YR'] || row['NUMBER OF STUDENTS IN 4-YEAR COHORT'],
      graduation_rate: row['REPORTYEAR_2017'] || row['GRADRATE4YR'] || row['4-YEAR GRADUATION RATE'],
      target_label: row['TARGET_LABEL'] || row['GRAD_TARGETS']
    }
    hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
    @main_arr  << hash
    h = {
      general_id: @general_id,
      graduation_type: '5-YEAR',#row['COHORT_TYPE'],#'4-YEAR' for 2012-2013
      suppressed: row['SUPPRESSED5YR'] || row['SUPPRESSED 5 YEAR'],
      school_year: @school_year,
      demographic: row["DISAGG_LABEL"] || row['DEMOGRAPHIC'],
      number_of_grads: row['COHORT_NUMERATOR'] || row['GRADS5YR'] || row['NUMBER OF GRADS IN 5-YEAR COHORT'],
      number_of_students: row['COHORT_DENOMINATOR'] || row['COHORT5YR'] || row['NUMBER OF STUDENTS IN 5-YEAR COHORT'],
      graduation_rate: row['REPORTYEAR_2017'] || row['GRADRATE5YR'] || row['5-YEAR GRADUATION RATE'],
      target_label: row['TARGET_LABEL'] || row['GRAD_TARGETS']
    }
    h.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(h))
    @main_arr  << h
  end

  def safety_events(row)
    get_district_id(row)
    #demographics = ['WHITE_CNT', 'BLACK_CNT', 'HISPANIC_CNT', 'ASIAN_CNT', 'AIAN_CNT', 'HAWAIIAN_CNT', 'OTHER_CNT', 'MALE_CNT', 'FEMALE_CNT', 'TOTAL_STDNT_CNT', 'TOTAL_UNIQUE_EVENT_CNT']
    demographics = ['WHITE_CNT', 'BLACK_CNT', 'HISPANIC_CNT', 'ASIAN_CNT', 'ALASKAN_CNT', 'HAWAIIAN_CNT', 'TWO_OR_MORE_CNT', 'MALE_CNT', 'FEMALE_CNT', 'TOTAL_STUDENTS', 'TOTAL_EVENTS']
    demographics.each_with_index do |value, index|
      hash = {
        general_id: @general_id,
        school_year: @school_year,
        demographic: demographics[index],
        group: row['RPT_HEADER'] || row['CONTENT_EVENT'] || row['TABLE'],
        name: row['RPT_LINE'] || row['CONTENT_LEVEL'] || row['CATEGORY'],
        count: row[demographics[index]]
      }
      hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
      @main_arr << hash
    end
  end

  def safety_events_csv(row)
    get_district_id(row)
    names = ['TOTAL EVENTS BY TYPE', 'ASSAULT 1ST DEGREE', 'OTHER ASSAULT OR VIOLENCE', 'WEAPONS', 'HARRASSMENT (INCLUDES BULLYING)',
      'DRUGS', 'ALCOHOL', 'TOBACCO', 'OTHER EVENTS W_STATE RESOLUTION', 'TOTAL EVENTS BY LOCATION', 'LOCATION - CLASSROOM',
      'LOCATION - BUS', 'LOCATION - HALLWAY/STAIRWAY', 'LOCATION - CAFETERIA', 'LOCATION - CAMPUS GROUNDS', 'LOCATION - RESTROOM',
      'LOCATION - GYMNASIUM', 'LOCATION - PLAYGROUND', 'LOCATION - OTHER', 'TOTAL EVENTS BY CONTEXT', 'SCHOOL SPONSORED SCHOOL HOURS',
      'SCHOOL SPONSORED NOT SCHOOL HOURS', 'NON-SCHOOL SPONSORED SCHOOL HOURS', 'NON-SCHOOL SPONSORED NOT SCHOOL HOURS',
      'TOTAL LEGAL SANCTIONS', 'ARRESTS', 'CHARGES', 'CIVIL DAMAGES', 'SCHOOL RESOURCE OFFICER INVOLVED', 'COURT DESIGNATED WORKED INVOLVED'
    ]
    names.each_with_index do |value, index|
      group = 'Behavior Events' if (0..8) === index
      group = 'Behavior Events by Location' if (9..18) === index
      group = 'Behavior Events by Context' if (19..23) === index
      group = 'Legal Sanctions' if (24..29) === index
      hash = {
        general_id: @general_id,
        school_year: @school_year,
        demographic: row['DEMOGRAPHIC'],
        name: names[index],
        group: group,
        count: row[value]
      }
      hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
      @main_arr << hash
    end
  end

  def safety_audit(row)
    get_district_id(row)
    hash = {
      general_id: @general_id,
      school_year: @school_year,
      safety_audit: row['School safety audit'],
      date:row['Date of school safety audit']
    }
    hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
    @main_arr << hash
  end

  def climate_index(row)
    get_district_id(row)
    hash = {
      general_id: @general_id,
      school_year: @school_year,
      demographic: row['DEMOGRAPHIC'],
      level: row['LEVEL'],
      suppressed: row['SUPPRESSED'],
      climate_index: row['CLIMATE INDEX'],
      safety_index: row['SAFETY INDEX']
    }
    hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
    @main_arr << hash
  end

  def climate(row)
    get_district_id(row)
    hash = {
      general_id: @general_id,
      school_year: @school_year,
      demographic: row['DEMOGRAPHIC'],
      level: row['LEVEL'],
      suppressed: row['SUPPRESSED'],
      question_number: row['QUESTION NUMBER'],
      question_type: row['QUESTION TYPE'],
      question: row['QUESTION'],
      strongly_disagree: row['STRONGLY DISAGREE'],
      disagree: row['DISAGREE'],
      agree: row['AGREE'],
      strongly_agree: row['STRONGLY AGREE'],
      agree_and_strongly_agree: row['AGREE AND STRONGLY AGREE'],
      question_index: row['QUESTION INDEX']
    }
    hash.merge!(run_id: @run_id, touched_run_id: @run_id, data_source_url: @source_url, md5_hash: create_md5_hash(hash))
    @main_arr << hash
  end

  def store_district
    KyGeneralInfo.insert_all(@main_arr)
    @main_arr.clear
    update_district_id
  end

  def store_administrators
    KyAdministrators.insert_all(@main_arr)
    @main_arr.clear
  end

  def store_enrollment
    KyEnrollment.insert_all(@main_arr)
    @main_arr.clear
  end

  def store_assessment
    KySchoolsAssessment.insert_all(@main_arr)
    KySchoolsAssessmentByLevels.insert_all(@assessment_lvl)
    @main_arr.clear
    @assessment_lvl.clear
  end

  def store_assessment_act
    KyAssessmentAct.insert_all(@main_arr)
    @main_arr.clear
  end

  def store_assesment_national
    KyAssesmentNational.insert_all(@main_arr)
    @main_arr.clear
  end
  
  def store_graduation_rate
    KyGraduationRate.insert_all(@main_arr)
    @main_arr.clear
  end

  def store_safety_events
    KySafetyEvents.insert_all(@main_arr)
    @main_arr.clear
  end

  def store_climate_index
    KySafetyClimateIndex.insert_all(@main_arr)
    @main_arr.clear
  end

  def store_climate
    KySafetyClimate.insert_all(@main_arr)
    @main_arr.clear
  end

  def store_safety_audit
    KySafetyAudit.insert_all(@main_arr)
    @main_arr.clear
  end

  def update_district_id
    school_code = KyGeneralInfo.select(:id, :school_code).where(is_district: true, district_id: nil).pluck(:id, :school_code)
    school_code.each do |code|
      KyGeneralInfo.where("school_code like '#{code[1]}%' and is_district = 0").update(district_id: code[0])
    end
  end 

  def create_md5_hash(hash)
    str = ""
    hash.each { |field| str += field.to_s}
    digest = Digest::MD5.new.hexdigest(str)
  end

  def get_district_id(row)
    dist_num = (row['DIST_NUMBER'] || row['DISTRICT NUMBER']) if row['SCH_CD'].nil?
    unless (row['SCH_NUMBER'] || row['SCHOOL NUMBER']).nil?
      sch_num = (row['SCH_NUMBER'] || row['SCHOOL NUMBER']) if row['SCH_CD'].nil?
    end
    row.merge!("SCH_CD"=> ("#{dist_num}#{sch_num}")) if row['SCH_CD'].nil?
    if row['SCH_NUMBER'] == '000'
      row['SCH_CD'] = row['SCH_CD'].split('').first(3).join
    end
    if @sch_cd != row['SCH_CD']
      district = KyGeneralInfo.find_by(school_code: row['SCH_CD'])
      if district.nil?
      @arr << row['SCH_CD']
      end
      @general_id = district.id rescue nil
      @sch_cd = row['SCH_CD']
    end
  end
end
