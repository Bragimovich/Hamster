require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'
require 'pry'

class Manager < Hamster::Scraper
  BASE_URL = "https://www.kyschoolreportcard.com"

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @dir_path = @_storehouse_ + 'filename_link.csv'
    @path = "#{storehouse}store/"
    @files_to_link = {}
    if File.file?(@dir_path)
      table = CSV.parse(File.read(@dir_path), headers: false)
      table.map{ |x| @files_to_link[x[0]] = x[1] }
    end
  end

  def scrape
    download
    store
  end

  def download
    download_all_csvs
    download_enrollment
    download_act
    download_dropout
    download_NAEP
    download_graduation_rate
    download_assessment_perfomance_by_grade
  end

  def store_for(year)
    store_general_info_for(year) #ky_general_info, ky_administrators: Loaded 2020, 2021, 2022, 2023
    store_enrollment_for(year) #ky_enrollment: 2020, 2021, 2022, 2023
    store_school_safety_for(year) #ky_safety_events: Loaded 2020, 2021, 2022, 2023
    store_precautionary_measure_for(year) #ky_safety_audit;: Loaded 2020, 2021, 2022, 2023, ky_safety_audit_measures
    store_safety_climate_for(year) #ky_safety_climate: Loaded 2021, 2022, 2023    (There is no data for <2020)
    store_safety_climate_index(year) #ky_safety_climate_index: Loaded 2022, 2023  (There is only 2022, 2023 data)
    store_graduation_rate_for(year) #ky_graduation_rate: 2018, 2019, 2020, 2021, 2022, 2023                   -- DONE
    store_assessment_act_for(year) #ky_assessment_act; Loaded 2018, 2019, 2021, 2022, 2023     (There is no data for 2020)
    store_assessment_national_for(year) #ky_assesment_national: Loaded 2018, 2019, 2020, 2022, 2022, 2023
    store_assessment_perfomance_by_grade_for(year) #ky_schools_assessment: Loaded 2021, 2022, 2023 (There is no data for <=2020)
  end

  def store_missing
    store_assessment_act_for(2019)
    store_assessment_act_for(2018)
  end


  def store
    store_general_infos
    store_enrollments
    store_school_safety
    store_precautionary_measures
    store_safety_climate
    store_safety_climate_index
    store_graduation_rate
    store_assessment_act
    store_assessment_national
    store_assessment_perfomance_by_grade
  end

  private

  def store_assessment_perfomance_by_grade
    file_names = [
      "asmt_performance_by_grade_2022.csv",
      "asmt_performance_by_grade_2021.csv"
    ]
    file_names.each do |file_name|
      data_source_url = @files_to_link[file_name]
      list_of_hashes = @parser.parse_assessment_perfomance_by_grade_csv(@path + file_name, data_source_url)
      assessment_perfomance_by_grades = attach_general_ids(list_of_hashes, data_source_url)
      assessment_perfomance_by_grades.each do |assessment_perfomance_by_grade|
        assessment_by_levels = assessment_perfomance_by_grade[:assessment_by_levels]
        id = @keeper.store_assessment_perfomance_by_grade(assessment_perfomance_by_grade.except(:assessment_by_levels))
        assessment_by_levels.map{ |hash| hash[:assessment_id] = id }
        @keeper.store_assessment_by_levels(assessment_by_levels)
      end
    end
  end

  def store_assessment_perfomance_by_grade_for(year)
    file_names = [
      "asmt_performance_by_grade_#{year.to_s}.csv"
    ]
    file_names.each do |file_name|
      data_source_url = @files_to_link[file_name]
      list_of_hashes = @parser.parse_assessment_perfomance_by_grade_csv(@path + file_name, data_source_url)
      assessment_perfomance_by_grades = attach_general_ids(list_of_hashes, data_source_url)
      logger.debug "started storing assessment_perfomance_by_grade rows: #{assessment_perfomance_by_grades.length}"
      assessment_perfomance_by_grades.each do |assessment_perfomance_by_grade|
        assessment_by_levels = assessment_perfomance_by_grade[:assessment_by_levels]
        id = @keeper.store_assessment_perfomance_by_grade(assessment_perfomance_by_grade.except(:assessment_by_levels))
        assessment_by_levels.map{ |hash| hash[:assessment_id] = id }
        @keeper.store_assessment_by_levels(assessment_by_levels)
      end
      logger.debug "finished storing assessment_perfomance_by_grade rows: #{assessment_perfomance_by_grades.length}"
    end
  end

  def store_general_infos
    file_names = [
      "district_school_list_2022.csv",
      "district_school_list_2021.csv",
      "district_school_list_2020.csv"
    ]
    file_names.each do |file_name|
      data_source_url = @files_to_link[file_name]
      store_general_info_table(@path + file_name, data_source_url)
    end
  end

  def store_general_info_for(year)
    if year >= 2020
      file_names = ["district_school_list_#{year.to_s}.csv"]
    else
      return
    end
    file_names.each do |file_name|
      data_source_url = @files_to_link[file_name]
      store_general_info_table(@path + file_name, data_source_url)
    end
  end

  def store_general_info_table(file_path, data_source_url)
    state = @keeper.store_general_info({name: "Kentucky", is_district: 0})
    districts, schools = @parser.parse_district_school_csv(file_path, data_source_url)
    districts.each do |district|
      contact_name = district[:contact_name]
      school_year = district[:school_year]
      general_id = @keeper.store_general_info(district.except(:contact_name, :school_year))
      hash = {role: "Superintendent", general_id: general_id, full_name: contact_name, school_year: school_year, data_source_url: data_source_url }
      @keeper.store_administrators(hash)
    end
    schools.each do |school|
      district_id = @keeper.get_general_id_by_district_name(school[:district_name])
      school[:district_id] = district_id
      school.delete(:district_name)
      contact_name = school[:contact_name]
      school_year = school[:school_year]
      general_id = @keeper.store_general_info(school.except(:contact_name, :school_year))
      hash = {role: "Principal", general_id: general_id, full_name: contact_name, school_year: school_year, data_source_url: data_source_url }
      @keeper.store_administrators(hash)
    end
  end
  
  def store_assessment_national
    file_names = [
      "NAEP_20172018.xlsx",
      "NAEP_20182019.xlsx"
    ]
    file_names.each do |file_name|
      data_source_url = @files_to_link[file_name]
      list_of_hashes = @parser.parse_assessment_national_xlsx(@path + file_name, data_source_url)
      @keeper.store_assessment_nationals(list_of_hashes)
    end
    file_names = [
      "national_assessment_of_educational_progress_2020.csv",
      "national_assessment_of_educational_progress_2021.csv",
      "national_assessment_of_educational_progress_2022.csv"
    ]
    file_names.each do |file_name|
      data_source_url = @files_to_link[file_name]
      list_of_hashes = @parser.parse_assessment_national_csv(@path + file_name, data_source_url)
      @keeper.store_assessment_nationals(list_of_hashes)
    end
  end

  def store_assessment_national_for(year)
    if year > 2019
      file_names = [
        "national_assessment_of_educational_progress_#{year.to_s}.csv"
      ]
      file_names.each do |file_name|
        data_source_url = @files_to_link[file_name]
        list_of_hashes = @parser.parse_assessment_national_csv(@path + file_name, data_source_url)
        @keeper.store_assessment_nationals(list_of_hashes)
      end
    else
      file_names = [
        "NAEP_#{year-1}#{year}.xlsx"
      ]
      file_names.each do |file_name|
        data_source_url = @files_to_link[file_name]
        list_of_hashes = @parser.parse_assessment_national_xlsx(@path + file_name, data_source_url)
        @keeper.store_assessment_nationals(list_of_hashes)
      end
    end
  end

  def store_assessment_act
    file_names =[
      "ASSESSMENT_PROFICIENCY_GRADE_20182019.xlsx",
      "ASSESSMENT_PROFICIENCY_GRADE_20172018.xlsx"
    ]

    file_names.each do |file_name|
      list_of_hashes = @parser.parse_assessment_act_xlsx(@path + file_name)
      data_source_url = @files_to_link[file_name]
    end

    file_names = [
      "cae_2021.csv",
      "cae_2022.csv",
    ]
    file_names.each do |file_name|
      list_of_hashes = @parser.parse_assessment_act_csv(@path + file_name)
      data_source_url = @files_to_link[file_name]
      assessment_acts = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_assessment_act(assessment_acts)
    end

    file_names = [
      "COLLEGE_ADMISSIONS_EXAM_20182019.xlsx",
      "COLLEGE_ADMISSIONS_EXAM_20172018.xlsx"
    ]
    file_names.each do |file_name|
      data_source_url = @files_to_link[file_name]
      list_of_hashes = @parser.parse_college_admission_exam_xlsx(@path + file_name, data_source_url)
      college_admission_exams = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_assessment_act(college_admission_exams)
    end
  end

  def store_assessment_act_for(year)
    if year >= 2021
      file_names = [
        "cae_#{year.to_s}.csv"
      ]
      file_names.each do |file_name|
        list_of_hashes = @parser.parse_assessment_act_csv(@path + file_name)
        data_source_url = @files_to_link[file_name]
        assessment_acts = attach_general_ids(list_of_hashes, data_source_url)
        @keeper.store_assessment_act(assessment_acts)
      end
    else
      file_names = [
        "COLLEGE_ADMISSIONS_EXAM_#{year-1}#{year}.xlsx",
      ]
      file_names.each do |file_name|
        data_source_url = @files_to_link[file_name]
        list_of_hashes = @parser.parse_college_admission_exam_xlsx(@path + file_name, data_source_url)
        college_admission_exams = attach_general_ids(list_of_hashes, data_source_url)
        @keeper.store_assessment_act(college_admission_exams)
      end
    end
  end

  def store_graduation_rate
    file_names = [
      "graduation_rate_2020.csv",
      "graduation_rate_2021.csv",
      "graduation_rate_2022.csv"
    ]
    file_names.each do |file_name|
      list_of_hashes = @parser.parse_graduation_rate(@path + file_name)
      data_source_url = @files_to_link[file_name]
      graduation_rates = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_graduation_rate(graduation_rates)
    end

    file_names = [
      "GRADUATION_RATE_20172018.xlsx",
      "GRADUATION_RATE_20182019.xlsx"
    ]
    
    file_names.each do |file_name|
      list_of_hashes = @parser.parse_graduation_rate_xlsx(@path + file_name)
      data_source_url = @files_to_link[file_name]
      graduation_rates = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_graduation_rate(graduation_rates)
    end
  end

  def store_graduation_rate_for(year)
    if year > 2019
      file_names = [
        "graduation_rate_#{year.to_s}.csv"
      ]
      file_names.each do |file_name|
        list_of_hashes = @parser.parse_graduation_rate(@path + file_name)
        data_source_url = @files_to_link[file_name]
        graduation_rates = attach_general_ids(list_of_hashes, data_source_url)
        @keeper.store_graduation_rate(graduation_rates)
      end
    else
      file_names = []
      if year == 2019
        file_names = [
          "GRADUATION_RATE_20182019.xlsx"
        ]
      end
      if year == 2018
        file_names = [
          "GRADUATION_RATE_20172018.xlsx"
        ]
      end
      file_names.each do |file_name|
        list_of_hashes = @parser.parse_graduation_rate_xlsx(@path + file_name)
        data_source_url = @files_to_link[file_name]
        graduation_rates = attach_general_ids(list_of_hashes, data_source_url)
        @keeper.store_graduation_rate(graduation_rates)
      end
    end
  end

  def store_safety_climate
    file_names = [
      "quality_of_school_climate_and_safety_survey_elementary_school_2021.csv",
      "quality_of_school_climate_and_safety_survey_elementary_school_2022.csv",
      "quality_of_school_climate_and_safety_survey_high_school_2021.csv",
      "quality_of_school_climate_and_safety_survey_high_school_2022.csv",
      "quality_of_school_climate_and_safety_survey_middle_school_2021.csv",
      "quality_of_school_climate_and_safety_survey_middle_school_2022.csv"
    ]
    
    file_names.each do |file_name|
      list_of_hashes = @parser.parse_safety_climate(@path + file_name)
      data_source_url = @files_to_link[file_name]
      safety_climate = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_safety_climate(safety_climate)
    end
  end

  def store_safety_climate_for(year)
    file_names = [
      "quality_of_school_climate_and_safety_survey_elementary_school_#{year}.csv",
      "quality_of_school_climate_and_safety_survey_high_school_#{year}.csv",
      "quality_of_school_climate_and_safety_survey_middle_school_#{year}.csv"
    ]
    
    file_names.each do |file_name|
      list_of_hashes = @parser.parse_safety_climate(@path + file_name)
      data_source_url = @files_to_link[file_name]
      safety_climate = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_safety_climate(safety_climate)
    end
  end
  
  def store_safety_climate_index(year)
    # file_name = "quality_of_school_climate_and_safety_survey_index_scores_2022.csv"
    file_name = "quality_of_school_climate_and_safety_survey_index_scores_#{year.to_s}.csv"
    list_of_hashes = @parser.parse_safety_climate_index(@path + file_name)
    data_source_url = @files_to_link[file_name]
    safety_climate_index = attach_general_ids(list_of_hashes, data_source_url)
    @keeper.store_safety_climate_index(safety_climate_index)
  end

  def store_precautionary_measures
    file_names = [
      "precautionary_measures_2021.csv",
      "precautionary_measures_2020.csv",
      "precautionary_measures_2022.csv",
    ]
    file_names.each do |file_name|
      list_of_hashes = @parser.parse_precautionary_measures(@path + file_name)
      data_source_url = @files_to_link[file_name]
      precautionary_measures = attach_general_ids(list_of_hashes, data_source_url)
      precautionary_measures.each do |hash|
        safety_measures = hash[:safety_measures]

        safety_audit = hash.except(:safety_measures)
        audit_id = @keeper.store_safety_audit(safety_audit)

        safety_measures.each do |hash|
          hash[:data_source_url] = data_source_url
          hash[:audit_id] = audit_id
        end
        @keeper.store_safety_audit_measures(safety_measures)
      end
    end
  end

  def store_precautionary_measure_for(year)
    file_names = [
      "precautionary_measures_#{year.to_s}.csv"
    ]
    file_names.each do |file_name|
      list_of_hashes = @parser.parse_precautionary_measures(@path + file_name)
      data_source_url = @files_to_link[file_name]
      precautionary_measures = attach_general_ids(list_of_hashes, data_source_url)
      logger.debug "started storing safety_audit_measures rows: #{precautionary_measures.length}"
      precautionary_measures.each do |hash|
        safety_measures = hash[:safety_measures]

        safety_audit = hash.except(:safety_measures)
        audit_id = @keeper.store_safety_audit(safety_audit)

        safety_measures.each do |hash|
          hash[:data_source_url] = data_source_url
          hash[:audit_id] = audit_id
        end
        @keeper.store_safety_audit_measures(safety_measures)
      end
      logger.debug "finished storing safety_audit_measures rows: #{precautionary_measures.length}"
    end
  end

  def attach_general_ids(list_of_hashes, data_source_url)
    list_to_return = []
    list_of_hashes.each do |hash|
      hash[:data_source_url] = data_source_url

      school_name = hash[:school_name]
      school_code = hash[:school_code]&.gsub('"',"")
      district_name = hash[:district_name]
      district_code = hash[:district_code]&.gsub('"',"")
     
      if school_name&.include?("District Total")
        hash[:general_id] = @keeper.get_general_id_by_district(district_name, district_code)
      elsif school_name&.include?("State Total")
        hash[:general_id] = @keeper.get_general_id_by_name("Kentucky")
      else
        # district_id = @keeper.get_general_id_by_district(district_name, district_code)
        hash[:general_id] = @keeper.get_general_id_by_school(school_name, district_code, school_code)
      end

      to_store = hash.except(:school_name, :school_code, :district_code, :district_name)
      list_to_return << to_store
    end
    list_to_return
  end

  def store_school_safety
    file_names = [
      "safe_schools_event_details_2020.csv",
      "safe_schools_event_details_2021.csv",
      "safe_schools_event_details_2022.csv"
    ]

    file_names.each do |file_name|
      list_of_hashes = @parser.parse_safety_events(@path + file_name)
      data_source_url = @files_to_link[file_name]
      safety_hashes = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_school_safety(safety_hashes)
    end
  end

  def store_school_safety_for(year)
    file_names = [
      "safe_schools_event_details_#{year.to_s}.csv"
    ]

    file_names.each do |file_name|      
      list_of_hashes = @parser.parse_safety_events(@path + file_name)
      data_source_url = @files_to_link[file_name]
      safety_hashes = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_school_safety(safety_hashes)
    end
  end


  def store_enrollments
    old_data_source_file_names = ["STUDENT_PRIMARY_ENROLLMENT_20182019.xlsx" ,"STUDENT_AGGREGATE_20172018.xlsx"]
    new_data_source_file_names =  [
      "primary_enrollment_2020.csv",
      "primary_enrollment_2021.csv",
      "primary_enrollment_2022.csv",
      "secondary_enrollment_2020.csv",
      "secondary_enrollment_2021.csv",
      "secondary_enrollment_2022.csv"
    ]
    new_data_source_file_names.each do |file_name|
      list_of_hashes =  @parser.parse_enrollment_csv(@path + file_name)
      data_source_url = @files_to_link[file_name]
      enrollments = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_enrollments(enrollments)
    end

    old_data_source_file_names.each do |file_name|
      list_of_hashes = @parser.parse_enrollment_xlsx(@path + file_name)
      data_source_url = @files_to_link[file_name]
      enrollments = attach_general_ids(list_of_hashes, data_source_url)
      @keeper.store_enrollments(enrollments)
    end
  end

  def store_enrollment_for(year)
    if year >= 2020
      new_data_source_file_names =  [
        "primary_enrollment_#{year.to_s}.csv",
        "secondary_enrollment_#{year.to_s}.csv"
      ]
      new_data_source_file_names.each do |file_name|
        list_of_hashes =  @parser.parse_enrollment_csv(@path + file_name)
        data_source_url = @files_to_link[file_name]
        enrollments = attach_general_ids(list_of_hashes, data_source_url)
        @keeper.store_enrollments(enrollments)
      end
    else
      if year == 2019
        old_data_source_file_names = ["STUDENT_PRIMARY_ENROLLMENT_#{year-1}#{year}.xlsx"]
      elsif year == 2018
        old_data_source_file_names = ["STUDENT_AGGREGATE_#{year-1}#{year}.xlsx"]
      end

      old_data_source_file_names.each do |file_name|
        list_of_hashes = @parser.parse_enrollment_xlsx(@path + file_name)
        data_source_url = @files_to_link[file_name]
        enrollments = attach_general_ids(list_of_hashes, data_source_url)
        @keeper.store_enrollments(enrollments)
      end
    end    
  end

  def download_all_csvs
    # for year 2021 & 2022
    response, status = @scraper.get_request(BASE_URL + "/datasets?year=2022")
    regex = /main.\d+\w+.js/
    result = response.body.match(regex)
    response, status = @scraper.get_request(BASE_URL + "/#{result.to_s}")
    csv_urls = response.body.scan(/https?:\/\/\S+?\.csv/).uniq
    # this will download all years data
    csv_urls.each do |csv_url|
      file_name = csv_url.split('/').last
      save_csv(file_name, csv_url)
      @scraper.download_csv_file(csv_url, file_name)
    end
  end

  def download_enrollment
    file_name_on_source = ["STUDENT_PRIMARY_ENROLLMENT.xlsx","STUDENT_AGGREGATE.xlsx"]
    years = ["20182019","20172018"]
    download_csvs(file_name_on_source, years)
  end

  def download_dropout
    file_names_on_source = ["DROPOUT.xlsx","DROPOUT.xlsx"]
    years = ["20182019","20172018"]
    download_csvs(file_names_on_source,years)
  end

  def download_act
    file_names_on_source = ["COLLEGE_ADMISSIONS_EXAM.xlsx","COLLEGE_ADMISSIONS_EXAM.xlsx"]
    years = ["20182019","20172018"]
    download_csvs(file_names_on_source, years)
  end

  def download_NAEP
    file_names_on_source =["NAEP.xlsx","NAEP.xlsx"] 
    years = ["20172018","20182019"]
    download_csvs(file_names_on_source, years)
  end

  def download_graduation_rate
    file_names_on_source = ["GRADUATION_RATE.xlsx","GRADUATION_RATE.xlsx"]
    years = ["20172018","20182019"]
    download_csvs(file_names_on_source, years)
  end

  def download_assessment_perfomance_by_grade
    file_names_on_source = ["ASSESSMENT_PROFICIENCY_GRADE.xlsx","ASSESSMENT_PROFICIENCY_GRADE.xlsx"]
    years = ["20172018","20182019"]
    download_csvs(file_names_on_source, years)
  end

  def download_csvs(file_names_on_source, years)
    logger.debug "download_csvs #{file_names_on_source}"
    download_path = "https://openhouse.education.ky.gov/Data/Download?"
    file_names_on_source.zip(years).each do |file_name, year|
      csv_url = download_path + "file=#{file_name}&path=SRC%5CDatasets%5C#{year}"
      name, ext = file_name.split(".")
      new_file_name = name + "_" + year + "." + ext
      save_csv(new_file_name, csv_url)
      @scraper.download_csv_file(csv_url, new_file_name)
    end
  end

  def save_csv(file_name, link)
    unless @files_to_link.key?(link)
      rows = [[file_name , link]]
      File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
    end
  end

end
