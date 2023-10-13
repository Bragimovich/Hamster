# frozen_string_literal: true

class Parser < Hamster::Harvester
  def initialize
    super
  end

  def parse_json_graduation(graduation, general_id)
    json = JSON.parse(graduation.body)
    graduation = []
    json.each do |js|
      year = js['schoolyear'].to_i - 1
      fetch_general_id = get_general_id(js)
      general_id_info =  general_id.select { |general| general[:number] == get_general_id(js) }[0][:id] rescue nil
      hash = {
        name: js['district'],
        number: fetch_general_id,
        general_id: general_id_info,
        school_year: year.to_s + '-' + js['schoolyear'],
        race: js['race'],
        gender: js['gender'],
        special_demo: js['gender'],
        geography: js['geography'],
        subgroup: js['subgroup'],
        rate_type: js['ratetype'],
        row_status: js['rowstatus'],
        graduates_cnt: js['graduates'],
        students: js['students'],
        graduates_pct: js['pctgraduates'],
        data_source_url: "https://data.delaware.gov/Education/Student-Graduation/t7e6-zcnn"
      }
      generate_md5_hash(%i[general_id school_year race gender special_demo geography subgroup rate_type row_status graduates_cnt students graduates_pct], hash)
      graduation << hash
    end
    graduation
  end

  def parse_json_growth(growth, general_id)
    json = JSON.parse(growth.body)
    growth = []
    json.each do |js|
      fetch_general_id = get_general_id(js)
      general_id_info =  general_id.select { |general| general[:number] == get_general_id(js) }[0][:id] rescue nil
      year = js['schoolyear'].to_i - 1
      hash = {
        name: js['district'],
        number: fetch_general_id,
        general_id: general_id_info,
        school_year: year.to_s + '-' + js['schoolyear'],
        race: js['race'],
        gender: js['gender'],
        grade: js['grade'],
        special_demo: js['specialdemo'],
        geography: js['geography'],
        subgroup: js['subgroup'],
        category: js['category'],
        row_status: js['rowstatus'],
        students: js['students'],
        target_met_avg_pct: js['avgpctoftargetmet'],
        data_source_url: "https://data.delaware.gov/Education/Student-Growth/kqmb-6xbs"
      }
      generate_md5_hash(%i[general_id school_year race gender grade special_demo geography subgroup category row_status students target_met_avg_pct], hash)
      growth << hash
    end
    growth
  end

  def parse_json_discipline(discipline, general_id)
    json = JSON.parse(discipline.body)
    discipline = []
    json.each do |js|
      fetch_general_id = get_general_id(js)
      general_id_info =  general_id.select { |general| general[:number] == get_general_id(js) }[0][:id] rescue nil
      year = js['schoolyear'].to_i - 1
      hash = {
        number: fetch_general_id,
        general_id: general_id_info,
        school_year: year.to_s + '-' + js['schoolyear'],
        race: js['race'],
        gender: js['gender'],
        grade: js['grade'],
        special_demo: js['specialdemo'],
        geography: js['geography'],
        subgroup: js['subgroup'],
        category: js['category'],
        row_status: js['rowstatus'],
        students: js['students'],
        enrollment_cnt: js['enrollment'],
        enrollment_pct: js['pctenrollment'],
        incidents: js['incidents'],
        duration_avg: js['avgduration'],
        data_source_url: "https://data.delaware.gov/Education/Student-Discipline/yr4w-jdi4"
      }
      generate_md5_hash(%i[general_id school_year race gender grade special_demo geography subgroup category row_status students enrollment_cnt enrollment_pct incidents duration_avg], hash)
      discipline << hash
    end
    discipline
  end

  def parse_json_salary(salary, general_id)
    json = JSON.parse(salary.body)
    salary = []
    json.each do |js|
      fetch_general_id = get_general_id(js)
      general_id_info =  general_id.select { |general| general[:number] == get_general_id(js) }[0][:id] rescue nil
      year = js['schoolyear'].to_i - 1
      hash = {
        number: fetch_general_id,
        general_id: general_id_info,
        school_year: year.to_s + '-' + js['schoolyear'],
        race: js['race'],
        gender: js['gender'],
        grade: js['grade'],
        special_demo: js['specialdemo'],
        geography: js['geography'],
        subgroup: js['subgroup'],
        staff_type: js['staff_type'],
        staff_category: js['staff_category'],
        job_classification: js['job_classification'],
        experience: js['experience'],
        educators: js['educators_fte'],
        total_salary_avg: js['average_total_salary'],
        state_salary_avg: js['average_state_salary'],
        local_salary_avg: js['average_local_salary'],
        federal_salary_avg: js['average_federal_salary'],
        experience_avg_years: js['average_years_of_experience'],
        age_avg_years: js['average_years_of_age'],
        data_source_url: 'https://data.delaware.gov/Education/Educator-Average-Salary/rv4m-vy79'
      }
      generate_md5_hash(%i[general_id school_year race gender grade special_demo geography subgroup staff_type staff_category job_classification experience educators total_salary_avg state_salary_avg local_salary_avg federal_salary_avg experience_avg_years age_avg_years], hash)
      salary << hash
    end
    salary
  end

  def parse_json_enrollment(enrollment, general_id)
    json = JSON.parse(enrollment.body)
    enrollment = []
    json.each do |js|
      fetch_general_id = get_general_id(js)
      general_id_info =  general_id.select { |general| general[:number] == get_general_id(js) }[0][:id] rescue nil
      year = js['schoolyear'].to_i - 1
      hash = {
        number: fetch_general_id,
        general_id: general_id_info,
        school_year: year.to_s + '-' + js['schoolyear'],
        race: js['race'],
        gender: js['gender'],
        grade: js['grade'],
        special_demo: js['specialdemo'],
        geography: js['geography'],
        subgroup: js['subgroup'],
        row_status: js['rowstatus'],
        students: js['students'],
        enrollment_eoy: js['eoyenrollment'],
        enrollment_eoy_pct: js['pctofeoyenrollment'],
        enrollment_fall: js['fallenrollment'],
        data_source_url: "https://data.delaware.gov/Education/Student-Enrollment/6i7v-xnmf"
      }
      generate_md5_hash(%i[general_id school_year race gender grade special_demo geography subgroup row_status students enrollment_eoy enrollment_eoy_pct enrollment_fall], hash)
      enrollment << hash
    end
    enrollment
  end

  def parse_json_assessment(assessment, general_id)
    json = JSON.parse(assessment.body)
    assessment = []
    json.each do |js|
      fetch_general_id = get_general_id(js)
      general_id_info =  general_id.select { |general| general[:number] == get_general_id(js) }[0][:id] rescue nil
      year = js['schoolyear'].to_i - 1
      hash = {
        number: fetch_general_id,
        general_id: general_id_info,
        school_year: year.to_s + '-' + js['schoolyear'],
        assessment_name: js['assessmentname'],
        subject: js['contentarea'],
        race: js['race'],
        gender: js['gender'],
        grade: js['grade'],
        special_demo: js['specialdemo'],
        geography: js['geography'],
        subgroup: js['subgroup'],
        row_status: js['rowstatus'],
        tested: js['tested'],
        proficient_cnt: js['proficient'],
        proficient_pct: js['ptcproficient'],
        scale_score_avg: js['scalescoreavg'],
        data_source_url: "https://data.delaware.gov/Education/Student-Assessment-Performance/ms6b-mt82"
      }
      generate_md5_hash(%i[general_id school_year assessment_name subject race gender grade special_demo geography subgroup row_status proficient_cnt proficient_pct scale_score_avg tested scale_score_avg], hash)
      assessment << hash
    end
    assessment
  end

  def generate_md5_hash(column, hash)
    md5 = MD5Hash.new(columns: column)
    md5.generate(hash)
    hash[:md5_hash] = md5.hash
  end

  def get_general_id(js)
    if js['schoolcode'] == '0' and js['districtcode'] == '0'
      general_id = '0'
    elsif js['districtcode'].to_i > 0
      general_id = js['districtcode']
    else
      general_id = js['schoolcode']
    end
  end
end
