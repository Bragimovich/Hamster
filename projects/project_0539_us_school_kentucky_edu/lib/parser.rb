# frozen_string_literal: true

require 'roo-xls'

class Parser < Hamster::Parser
  def initialize
    super
  end

  def parse_college_admission_exam_xlsx(file_name, data_source_url)
    xls = Roo::Spreadsheet.open(file_name)
    data_sheet = xls.sheet("DATA")

    # as_json method will convert the data into array format
    list = data_sheet&.as_json
    headers = list[0]
    list_of_dicts = get_list_of_dicts_prime(list)

    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCH_YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"
      temp = {}
      temp[:district_code] =  hash["DIST_NUMBER"]
      temp[:district_name] = hash["DIST_NAME"]
      temp[:school_name] = hash["SCH_NAME"]
      temp[:school_code] = hash["SCH_CD"]
      temp[:school_year] = school_year
      temp[:demographic] = hash["DEMOGRAPHIC"]
      temp[:suppressed_average] = hash["SUPPRESSEDAVG"]

      name = [
        'English',
        'Reading',
        'Math',
        'Science',
        'Composite'
      ]

      mean_score = [
        'AVG_ENG',
        'AVG_RD',
        'AVG_MA',
        'AVG_SC',
        'AVG_COMP'
      ]

      benchmarks = [
        'ENG_BENCH',
        'RD_BENCH',
        'MA_BENCH'
      ]

      temp[:data_source_url] = data_source_url
      
      mean_score.each_with_index do |value, index|
        tmp = {
          subject: name[index],
          average_act_scores: hash[value],
          percent_meeting_benchmarks: hash[benchmarks[index]]
        }
        list_of_hashes << temp.merge(tmp)
      end
    end
    list_of_hashes
  end

  def parse_assessment_perfomance_by_grade_csv(file_name, data_source_url)
    logger.debug "started parsing assessment_perfomance_by_grade_csv from #{file_name}"
    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"
      temp = {}

      temp[:district_code] =  hash["DISTRICT NUMBER"]
      temp[:district_name] = hash["DISTRICT NAME"]
      temp[:school_name] = hash["SCHOOL NAME"]
      temp[:school_code] = hash["SCHOOL CODE"]

      temp[:school_year] = school_year
      temp[:exam_name] = "Kentucky Summative Assessments"
      temp[:grade] = hash["GRADE"]
      temp[:subject] = hash["SUBJECT"]
      temp[:demographic] = hash["DEMOGRAPHIC"]
      temp[:data_source_url] = data_source_url
      assessment_by_levels = [
        {
          level: "NOVICE",
          count: hash["NOVICE"],
          data_source_url: data_source_url
        },
        {
          level: "APPRENTICE",
          count: hash["APPRENTICE"],
          data_source_url: data_source_url
        },
        {
          level: "PROFICIENT",
          count: hash["PROFICIENT"],
          data_source_url: data_source_url
        },
        {
          level: "DISTINGUISHED",
          count: hash["DISTINGUISHED"],
          data_source_url: data_source_url
        },
        {
          level: "PROFICIENT/DISTINGUISHED",
          count: hash["PROFICIENT/DISTINGUISHED"],
          data_source_url: data_source_url
        }
      ]
      temp[:assessment_by_levels] = assessment_by_levels
      list_of_hashes << temp
    end
    logger.debug "finished parsing assessment_perfomance_by_grade_csv from #{file_name}"
    list_of_hashes
  end

  def parse_graduation_rate_xlsx(file_name)
    xls = Roo::Spreadsheet.open(file_name)
    data_sheet = xls.sheet("DATA")
    # as_json method will convert the data into array format
    list = data_sheet&.as_json
    list_of_dicts = get_list_of_dicts_prime(list)
    list_of_hashes = []

    list_of_dicts.each do |hash|
      school_year = hash["SCH_YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"
      temp = {}
      temp[:district_code] =  hash["DIST_NUMBER"]
      temp[:district_name] = hash["DIST_NAME"]
      temp[:school_name] = hash["SCH_NAME"]
      temp[:school_code] = hash["SCH_CD"]
      temp[:school_year] = school_year
      temp[:demographic] = hash["DEMOGRAPHIC"]
      
      four_year_cohort = {
        graduation_type: '4-YEAR',
        number_of_grads: hash["GRADS4YR"],
        number_of_students: hash["COHORT4YR"],
        graduation_rate: hash['GRADRATE4YR'],
        suppressed: hash["SUPPRESSED4YR"]
      }

      five_year_cohort = {
        graduation_type: '5-YEAR',
        number_of_grads: hash["GRADS5YR"],
        number_of_students: hash["COHORT5YR"],
        graduation_rate: hash["GRADRATE5YR"],
        suppressed: hash["SUPPRESSED5YR"]
      }

      hash1 = temp.merge(four_year_cohort)
      hash2 = temp.merge(five_year_cohort)

      list_of_hashes << hash1
      list_of_hashes << hash2
    end
    list_of_hashes
  end

  def parse_assessment_national_csv(file_name, data_source_url)
    logger.debug "started parsing assessment_national_csv from #{file_name}"
    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"
      temp = {}
      temp[:school_year] = school_year
      temp[:demographic] = hash["DEMOGRAPHIC"]
      temp[:level] = hash["LEVEL"]
      temp[:grade] = hash["GRADE"]
      temp[:subject] = hash["SUBJECT"]
      temp[:percent_below_basic_level] = hash["PERCENT OF STUDENTS BELOW BASIC LEVEL"]
      temp[:percent_at_basic_level] = hash["PERCENT OF STUDENTS AT BASIC LEVEL"]
      temp[:percent_procient] = hash["PERCENT PROFICIENT"]
      temp[:percent_at_advanced_level] = hash["PERCENT OF STUDENTS AT ADVANCED LEVEL"]
      temp[:parcipation_rate] = hash["PARTICIPATION RATE"]
      temp[:data_source_url] = data_source_url
      list_of_hashes << temp
    end
    logger.debug "finished parsing assessment_national_csv from #{file_name}"
    list_of_hashes
  end

  def parse_assessment_national_xlsx(file_name, data_source_url)
    xls = Roo::Spreadsheet.open(file_name)
    data_sheet = xls.sheet("DATA")
    # as_json method will convert the data into array format
    list = data_sheet&.as_json
    list_of_dicts = get_list_of_dicts_prime(list)
    list_of_hashes = []

    list_of_dicts.each do |hash|
      school_year = hash["SCH_YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"

      temp = {}
      temp[:school_year] = school_year
      temp[:demographic] = hash["DEMOGRAPHIC"]
      temp[:level] = hash["LEVEL"]
      temp[:grade] = hash["GRADE"]
      temp[:subject] = hash["SUBJECT"]
      temp[:percent_below_basic_level] = hash["BELOWBASIC"]
      temp[:percent_at_basic_level] = hash["ATBASIC"] 
      temp[:percent_procient] = hash["ATPROFICIENT"]
      temp[:percent_at_advanced_level] = hash["ATADVANCED"]
      temp[:parcipation_rate] = hash["PARTICIPATIONRATE"]
      temp[:data_source_url] = data_source_url
      list_of_hashes << temp
    end
    list_of_hashes
  end

  def parse_assessment_act_xlsx(file_name)
    xls = Roo::Spreadsheet.open(file_name)
    data_sheet = xls.sheet("DATA")
    # as_json method will convert the data into array format
    list = data_sheet&.as_json
    list_of_dicts = get_list_of_dicts_prime(list)
    list_of_hashes = []
  end

  def parse_assessment_act_csv(file_name)
    logger.debug "started parsing assessment_act_csv from #{file_name}"
    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"
      temp = {}
      temp[:district_code] =  hash["DISTRICT NUMBER"]
      temp[:district_name] = hash["DISTRICT NAME"]
      temp[:school_name] = hash["SCHOOL NAME"]
      temp[:school_code] = hash["SCHOOL CODE"]
      temp[:school_year] = school_year

      temp[:demographic] = hash["DEMOGRAPHIC"]
      temp[:suppressed_average] = hash['Suppressed Average Score']
      temp[:suppressed_benchmarks] = hash['Suppressed Benchmark Scores']

      name = [
        'English', 
        'Reading',
        'Math',
        'Science',
        'Composite'
      ]

      mean_score = [
        'Average ACT Scores: English',
        'Average ACT Scores: Reading',
        'Average ACT Scores: Math',
        'Average ACT Scores: Science',
        'Average ACT Composite Score'
      ]

      benchmarks = [
        'Number of Students Meeting Benchmarks: English',
        'Number of Students Meeting Benchmarks: Reading',
        'Number of Students Meeting Benchmarks: Math'
      ]
      
      mean_score.each_with_index do |value, index|
        tmp = {
          subject: name[index],
          average_act_scores: hash[value],
          percent_meeting_benchmarks: hash[benchmarks[index]]
        }
        list_of_hashes << temp.merge(tmp)
      end
    end
    logger.debug "finished parsing assessment_act_csv from #{file_name}"
    list_of_hashes
  end

  def parse_graduation_rate(file_name)
    logger.debug "started parsing graduation_rate from #{file_name}"
    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"
      temp = {}
      temp[:district_code] =  hash["DISTRICT NUMBER"]
      temp[:district_name] = hash["DISTRICT NAME"]
      temp[:school_name] = hash["SCHOOL NAME"]
      temp[:school_code] = hash["SCHOOL CODE"]
      temp[:school_year] = school_year
      temp[:demographic] = hash["DEMOGRAPHIC"]
      
      four_year_cohort = {
        graduation_type: '4-YEAR',
        number_of_grads: hash["NUMBER OF GRADS IN 4-YEAR COHORT"],
        number_of_students: hash["NUMBER OF STUDENTS IN 4-YEAR COHORT"],
        graduation_rate: hash['4-YEAR GRADUATION RATE'],
        suppressed: hash["SUPPRESSED 4 YEAR"]
      }

      five_year_cohort = {
        graduation_type: '5-YEAR',
        number_of_grads: hash["NUMBER OF GRADS IN 5-YEAR COHORT"],
        number_of_students: hash["NUMBER OF STUDENTS IN 5-YEAR COHORT"],
        graduation_rate: hash["5-YEAR GRADUATION RATE"],
        suppressed: hash["SUPPRESSED 5 YEAR"]
      }

      hash1 = temp.merge(four_year_cohort)
      hash2 = temp.merge(five_year_cohort)

      list_of_hashes << hash1
      list_of_hashes << hash2
    end
    logger.debug "finished parsing graduation_rate from #{file_name}"
    list_of_hashes
  end

  def parse_safety_climate_index(file_name)
    logger.debug "started parsing safety_climate_index from #{file_name}"
    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"
      temp = {}
      temp[:district_code] =  hash["DISTRICT NUMBER"]
      temp[:district_name] = hash["DISTRICT NAME"]
      temp[:school_name] = hash["SCHOOL NAME"]
      temp[:school_code] = hash["SCHOOL CODE"]
      temp[:school_year] = school_year
      temp[:level] = hash["LEVEL"]
      temp[:demographic] = hash["DEMOGRAPHIC"]
      temp[:suppressed] = hash["SUPPRESSED"]
      temp[:climate_index] = hash["CLIMATE INDEX"]
      temp[:safety_index] = hash["SAFETY INDEX"]
      list_of_hashes << temp
    end
    logger.debug "finished parsing safety_climate_index from #{file_name}"
    list_of_hashes
  end

  def parse_safety_climate(file_name)
    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"
      temp = {}
      temp[:district_code] =  hash["DISTRICT NUMBER"]
      temp[:district_name] = hash["DISTRICT NAME"]
      temp[:school_name] = hash["SCHOOL NAME"]
      temp[:school_code] = hash["SCHOOL CODE"]
      temp[:school_year] = school_year
      temp[:level]  = hash["LEVEL"]
      temp[:demographic] = hash["DEMOGRAPHIC"]
      temp[:question_number] = hash["QUESTION NUMBER"]
      temp[:question_type] = hash["QUESTION TYPE"]
      temp[:question] = hash["QUESTION"]
      temp[:suppressed] = hash["SUPPRESSED"]
      temp[:strongly_disagree] = hash["STRONGLY DISAGREE"]
      temp[:disagree] = hash["DISAGREE"]
      temp[:agree] = hash["AGREE"]
      temp[:strongly_agree] = hash["STRONGLY AGREE"]
      temp[:agree_and_strongly_agree] = hash["AGREE AND STRONGLY AGREE"]
      temp[:question_index] = hash["QUESTION INDEX"]
      list_of_hashes << temp
    end
    list_of_hashes
  end

  def parse_precautionary_measures(file_name)
    logger.debug "started parsing precautionary_measures from #{file_name}"
    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"

      temp = {}
      temp[:district_code] =  hash["DISTRICT NUMBER"]
      temp[:district_name] = hash["DISTRICT NAME"]
      temp[:school_name] = hash["SCHOOL NAME"]
      temp[:school_code] = hash["SCHOOL CODE"]
      temp[:school_year] = school_year
      temp[:safety_audit] = hash["School safety audit"]
      temp[:date] = hash["Date of school safety audit"]

      safety_measures = []
      hash.keys[13..-1].each do |measure|
        tmp = {}
        tmp[:measure] = measure
        tmp[:value] = hash[measure]
        safety_measures << tmp
      end
      temp[:safety_measures] = safety_measures
      list_of_hashes << temp
    end
    logger.debug "finished parsing precautionary_measures from #{file_name}"
    list_of_hashes
  end

  def parse_safety_events(file_name)
    logger.debug "started parsing safety_events from #{file_name}"
    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)

    event_by_type = [
      "TOTAL EVENTS BY TYPE",
      "ASSAULT 1ST DEGREE",
      "OTHER ASSAULT OR VIOLENCE",
      "WEAPONS",
      "HARRASSMENT (INCLUDES BULLYING)",
      "DRUGS",
      "ALCOHOL",
      "TOBACCO",
      "OTHER EVENTS W_STATE RESOLUTION"
    ]

    event_by_location = [
      "TOTAL EVENTS BY LOCATION",
      "LOCATION - CLASSROOM",
      "LOCATION - BUS",
      "LOCATION - HALLWAY/STAIRWAY",
      "LOCATION - CAFETERIA",
      "LOCATION - CAMPUS GROUNDS",
      "LOCATION - RESTROOM",
      "LOCATION - GYMNASIUM",
      "LOCATION - PLAYGROUND",
      "LOCATION - OTHER",
    ]

    event_by_context = [
      "TOTAL EVENTS BY CONTEXT",
      "SCHOOL SPONSORED SCHOOL HOURS",
      "SCHOOL SPONSORED NOT SCHOOL HOURS",
      "NON-SCHOOL SPONSORED SCHOOL HOURS",
      "NON-SCHOOL SPONSORED NOT SCHOOL HOURS",
      "TOTAL LEGAL SANCTIONS",
      "ARRESTS",
      "CHARGES",
      "CIVIL DAMAGES",
      "SCHOOL RESOURCE OFFICER INVOLVED",
      "COURT DESIGNATED WORKED INVOLVED"
    ]

    groups = {
      'Events by type': event_by_type,
      'Events by location': event_by_location,
      'Events by context': event_by_context
    }

    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"

      groups.keys.each do |group|
        groups[group].each do |type|
          temp = {}
          temp[:district_code] =  hash["DISTRICT NUMBER"]
          temp[:district_name] = hash["DISTRICT NAME"]
          temp[:school_name] = hash["SCHOOL NAME"]
          temp[:school_code] = hash["SCHOOL CODE"]
          temp[:school_year] = school_year
          temp[:group] = group

          if ["TOTAL EVENTS BY TYPE", "TOTAL EVENTS BY LOCATION", "TOTAL EVENTS BY CONTEXT"].include?(type)
            temp[:name] = "Total"
          else
            temp[:name] = type
          end

          temp[:count] = hash[type]
          list_of_hashes << temp
        end
      end
    end
    logger.debug "finished parsing safety_events from #{file_name}"
    list_of_hashes
  end

  def parse_enrollment_csv(file_name)
    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    grades = ['TOTAL STUDENT COUNT', 'PRESCHOOL COUNT', 'KINDERGARTEN COUNT',	'GRADE1 COUNT', 'GRADE2 COUNT', 'GRADE3 COUNT', 'GRADE4 COUNT', 'GRADE5 COUNT', 'GRADE6 COUNT', 'GRADE7 COUNT', 'GRADE8 COUNT', 'GRADE9 COUNT', 'GRADE10 COUNT', 'GRADE11 COUNT', 'GRADE12 COUNT', 'GRADE14 COUNT']
    list_of_dicts.each do |hash|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"
      grades.each do |grade|
        temp = {}
        temp[:district_code] =  hash["DISTRICT NUMBER"]
        temp[:district_name] = hash["DISTRICT NAME"]
        temp[:school_name] = hash["SCHOOL NAME"]
        temp[:school_code] = hash["SCHOOL CODE"]
        temp[:demographic] =  hash["DEMOGRAPHIC"]
        temp[:grade] = grade
        temp[:count] =  hash[grade]
        temp[:school_year] = school_year
        list_of_hashes << temp
      end
    end
    list_of_hashes
  end
  
  def parse_enrollment_xlsx(file_name)
    xls = Roo::Spreadsheet.open(file_name)
    data_sheet = xls.sheet("DATA")
    # as_json method will convert the data into array format
    list = data_sheet&.as_json
    list_of_dicts = get_list_of_dicts_prime(list)
    list_of_hashes = []
    list_of_dicts.each do |hash|
      school_year = hash["SCH_YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"

      grades = ['TOTALSTUDENTS', 'P_CNT', 'K_CNT', 'G1_CNT', 'G2_CNT', 'G3_CNT', 'G4_CNT', 'G5_CNT', 'G6_CNT', 'G7_CNT', 'G8_CNT', 'G9_CNT', 'G10_CNT', 'G11_CNT', 'G12_CNT', 'G14_CNT']
      grades.each do |grade|
        temp = {}
        temp[:district_code] =  hash["DIST_NUMBER"]
        temp[:district_name] = hash["DIST_NAME"]
        temp[:school_name] = hash["SCH_NAME"]
        temp[:school_code] = hash["SCH_NUMBER"]
        temp[:demographic] =  hash["STUDENTGROUP"]
        temp[:grade] = grade
        temp[:count] =  hash[grade]
        temp[:school_year] = school_year
        list_of_hashes << temp
      end
    end
    list_of_hashes
  end


  def get_list_of_dicts(list)
    headers = list[0][0]
    list_of_dicts = list[1..-1].map{|val| headers.zip(val[0]).to_h}
    list_of_dicts
  end

  def parse_district_school_csv(file_name, data_source_url)
    logger.debug "Started parsing district_school_csv #{file_name}"

    list = csv_parser(file_name)
    list_of_dicts = get_list_of_dicts(list)
    districts = []
    schools = []
    list_of_dicts.each_with_index do |hash, index|
      school_year = hash["SCHOOL YEAR"]
      school_year = "#{school_year[..3]}-#{school_year[4..]}"

      temp = {
        school_year: school_year,
        data_source_url: data_source_url,
        county_number: hash["COUNTY NUMBER"],
        nces_id: hash["NCES ID"],
        coop_code: hash["CO-OP CODE"],
        coop_name: hash["CO-OP"],
        low_grade: hash["LOW GRADE"],
        high_grade: hash["HIGH GRADE"],
        title_1_status: hash["TITLE I STATUS"],
        phone: hash["PHONE"],
        fax: hash["FAX"],
        address: hash["ADDRESS"],
        city: hash["CITY"],
        county: hash["COUNTY NAME"],
        state: hash["STATE"],
        zip: hash["ZIPCODE"],
        lat: hash["LATITUDE"],
        lon: hash["LONGITUDE"],
        contact_name: hash["CONTACT NAME"]
      }
      
      if hash["SCHOOL NAME"]&.include?("District Total")
        district = {
          is_district: 1,
          number: hash["DISTRICT NUMBER"],
          name: hash["DISTRICT NAME"],
        }
        districts << district.merge(temp)
      else
        school = {
          is_district: 0,
          number: hash["SCHOOL NUMBER"],
          name: hash["SCHOOL NAME"],
          school_code: hash["SCHOOL CODE"],
          state_school_id: hash["STATE SCHOOL ID"],
          school_type: hash["SCHOOL TYPE"],
          district_name: hash["DISTRICT NAME"]
        }
        schools << school.merge(temp)
      end
    end
    logger.debug "Finished parsing district_school_csv #{file_name}"
    [districts, schools]
  end

  def get_list_of_dicts_prime(list)
    headers = list[0]
    list_of_dicts = list[1..-1].map{|val| headers.zip(val).to_h}
    list_of_dicts
  end


  def csv_parser(file_name, lines_to_skip=0)
    lines = File.open(file_name, "r").readlines

    lines = lines[lines_to_skip..-1]
    list = []
    lines.each do |line|
      line = line.encode("UTF-8", invalid: :replace, replace: "")
      row = CSV.parse(line)
      list << row
    end
    list
  end
end
