# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper

  def initialize
    super
    @path = "#{storehouse}store/"
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    download_enrollment
    download_per_pupil_expenditures_by_function_district
    download_performance_index
    download_sat
    download_smarter_balanced
    download_next_generation_science_standards
  end
  
  def store
    @keeper.sync_general_info_table
    parse_enrollment
    district_expenditures
    parse_performance_index
    parse_sat
    parse_smarter_balanced
    parse_next_generation_science_standards
    @keeper.finish
  end
  
  private
  
  def parse_next_generation_science_standards
    files = peon.list()
    req_files = files.select{|x| x.match(/next_generation_science/) }
    req_files.each do |file|
      next if file.include?("Trend")
      file_name = @path + file
      list_of_hashes = @parser.parse_next_generation_science_standards(file_name)
      list_of_hashes.each do |hash|
        school_name = hash[:school_name]
        school_code = hash[:school_code]&.gsub('"',"")
        district_name = hash[:district_name]
        district_code = hash[:district_code]&.gsub('"',"")

        district_id = @keeper.get_general_id_by_district(district_name, district_code)
        hash[:general_id] = @keeper.get_general_id_by_school(school_name, school_code, district_id)

        # store assement
        assement = hash.except(:school_name, :school_code, :assement_by_levels, :district_name, :district_code)
        assement_id = @keeper.store_school_assesments(assement)
        
        assement_by_levels = hash[:assement_by_levels]
        assement_by_levels.each do |h|
          h[:assessment_id] = assement_id
        end

        @keeper.store_schools_assesments_by_level(assement_by_levels)
      end
    end
  end

  def parse_smarter_balanced
    files = peon.list()
    req_files = files.select{|x| x.match(/smarter_balanced/) }

    req_files.each do |file|
      next if file.include?("Trend")
      file_name = @path + file
      list_of_hashes = @parser.parse_smarter_balanced_csv(file_name)
      list_of_hashes.each do |hash|
        district_name = hash[:district_name]
        hash['general_id'] = @keeper.get_general_id_by_name(district_name)

        # store assement
        assement = hash.except(:school_name, :school_code, :assement_by_levels, :district_name)
        assement_id = @keeper.store_school_assesments(assement)
        
        assement_by_levels = hash[:assement_by_levels]
        assement_by_levels.each do |h|
          h[:assessment_id] = assement_id
        end

        @keeper.store_schools_assesments_by_level(assement_by_levels)
      end
    end
  end

  def download_enrollment
    base_url = "https://public-edsight.ct.gov/Students/Enrollment-Dashboard/Enrollment-Report-Legacy?language=en_US"
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_year=2021-22&_district=All+Districts&_school=All+Schools&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FEnrollmentReport_SiteCore"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses//EnrollmentYearExport&_year={year_option}&_district=All+Districts&_school=All+Schools&display=1&_subgroup=Race"
    file_name = "enrollment"
    download_csvs(base_iframe, url, file_name)
  end

  def download_per_pupil_expenditures_by_function_district
    base_url = "https://public-edsight.ct.gov/overview/per-pupil-expenditures-by-function---district?language=en_US"
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_year=2020-21&_district=All+Districts&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FEFSDistrictLevelbyFunctionReport_SiteCore&_select=Submit"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/EFSDistrictLevelbyFunctionExport&_year={year_option}&_district=All+Districts"
    file_name = "pupil_expenditures"
    download_csvs(base_iframe, url, file_name)
  end

  def download_performance_index
    base_url = "https://public-edsight.ct.gov/performance/performance-index?language=en_US"
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_subject=All+Subjects&_year=Trend&_district=State+of+Connecticut&_school=&_subgroup=++&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FPerformanceIndexReport_SiteCore&_select=Submit"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/PerformanceIndexExport&_year={year_option}&_district=All+Districts&_school=All+Schools&_subgroup=+&_subject=All+Subjects"
    file_name = "perfomance_index"
    download_csvs(base_iframe, url, file_name)
  end

  def download_sat
    base_url = "https://public-edsight.ct.gov/performance/connecticut-school-day-sat?language=en_US"
    base_iframe ="https://edsight.ct.gov/SASStoredProcess/guest?_year=Trend&_district=All+Districts&_school=All+Schools&_subject=All+Subjects&_subgroup=All+Students+&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FCTSchoolDaySATReport_SiteCore"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/CTSchoolDaySATExport&_year={year_option}&_district=All+Districts&_subgroup=All+Students&_school=All+Schools&_subject=All+Subjects"
    file_name = "sat_school"
    download_csvs(base_iframe, url, file_name)

    #=================================For State of connecticut======================================================================
    base_url = "https://public-edsight.ct.gov/performance/smarter-balanced-achievement-participation?language=en_US"
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_grade=All+Grades&_year=Trend&_district=State+of+Connecticut&_school=All+Schools&_subject=ELA+and+Math&_subgroup=All+Students+&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FSmarterBalancedAssessmentReport_SiteCore"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/SmarterBalancedAssessmentExport&_year={year_option}&_district=State+of+Connecticut&_subgroup=All+Students&_school=+&_subject=ELA+and+Math&_grade=All+Grades"

    file_name = "sat_for_state_of_connecticut"
    download_csvs(base_iframe, url, file_name)

    # =============================Sat data by Race/Ethnicity===========================================================================
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_year=2021-22&_district=All+Districts&_school=&_subject=All+Subjects&_subgroup=Race+&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FCTSchoolDaySATReport_SiteCore"
    url ="https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/CTSchoolDaySATExport&_year={year_option}&_district=All+Districts&_subgroup=Race&_school=+&_subject=All+Subjects"
    file_name = "sat_data_aggreagated_by_race_ethnicity"
    download_csvs(base_iframe, url, file_name)
  end

  def download_next_generation_science_standards
    base_url = "https://public-edsight.ct.gov/performance/ngss-assessment?language=en_US"
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_grade=All+Grades&_year=Trend&_district=All+Districts&_school=All+Schools&_subgroup=All+Students+&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FNextGenerationScienceStandardsReport_SiteCore"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/NextGenerationScienceStandardsExport&_year={year_option}&_district=All+Districts&_subgroup=All+Students&_school=All+Schools&_grade=All+Grades"
    file_name = "next_generation_science_standards"
    download_csvs(base_iframe, url, file_name)

    # ============For All Grades Combined==========================================
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_grade=All+Grades+Combined&_year=Trend&_district=All+Districts&_school=All+Schools&_subgroup=All+Students+&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FNextGenerationScienceStandardsReport_SiteCore&_select=Submit"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/NextGenerationScienceStandardsExport&_year={year_option}&_district=All+Districts&_subgroup=All+Students&_school=All+Schools&_grade=All+Grades+Combined"
    file_name = "next_generation_science_standards_for_all_grades"
    download_csvs(base_iframe, url, file_name)
  end

  def download_csvs(base_iframe, url, file_name)
    response, status = @scraper.get_request(base_iframe)
    year_list = @parser.get_year_options_from_page(response.body)
    year_list.each do |year_option|
      _url = url.gsub("{year_option}", year_option)
      _file_name = @path + "#{file_name}_#{year_option}.csv"
      response, status = @scraper.download_csv_file(_url, _file_name)
    end
  end

  def download_smarter_balanced
    base_url = "https://public-edsight.ct.gov/performance/smarter-balanced-achievement-participation?language=en_US"
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_grade=All+Grades&_year=Trend&_district=All+Districts&_school=All+Schools&_subject=ELA+and+Math&_subgroup=All+Students+&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FSmarterBalancedAssessmentReport_SiteCore"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/SmarterBalancedAssessmentExport&_year={year_option}&_district=All+Districts&_subgroup=All+Students&_school=All+Schools&_subject=ELA+and+Math&_grade=All+Grades"
    file_name = "smarter_balanced"
    download_csvs(base_iframe, url, file_name)

    # ==================For state of connecticut========================================================================================
    base_url = "https://public-edsight.ct.gov/performance/smarter-balanced-achievement-participation?language=en_US"
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_grade=All+Grades&_year=Trend&_district=State+of+Connecticut&_school=All+Schools&_subject=ELA+and+Math&_subgroup=All+Students+&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FSmarterBalancedAssessmentReport_SiteCore"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/SmarterBalancedAssessmentExport&_year={year_option}&_district=State+of+Connecticut&_subgroup=All+Students&_school=+&_subject=ELA+and+Math&_grade=All+Grades"

    file_name = "smarter_balanced_for_state_of_connecticut"
    download_csvs(base_iframe, url, file_name)

    # =====================For all grades combined==========================
    base_iframe = "https://edsight.ct.gov/SASStoredProcess/guest?_grade=All+Grades+Combined&_year=2018-19&_district=State+of+Connecticut&_school=&_subject=ELA+and+Math&_subgroup=All+Students+&_program=%2FCTDOE%2FEdSight%2FRelease%2FReporting%2FPublic%2FReports%2FStoredProcesses%2FSmarterBalancedAssessmentReport_SiteCore"
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/SmarterBalancedAssessmentExport&_year={year_option}&_district=State+of+Connecticut&_subgroup=All+Students&_school=+&_subject=ELA+and+Math&_grade=All+Grades+Combined"
    file_name = "smarter_balanced_for_all_grades_combined"
    download_csvs(base_iframe, url, file_name)
  end

  def download_organization_information
    url = "https://edsight.ct.gov/SASStoredProcess/guest?_program=/CTDOE/EdSight/Release/Reporting/Public/Reports/StoredProcesses/OrgSearchExport&orgtype=+&orgdistrict=+&orgname=+&orgeduprg=+&orgprgtype=+&_keyword=+"
    file_name = @path + "organization_information.csv"
    response, status = @scraper.download_csv_file(url, file_name)
  end

  def parse_sat
    files = peon.list()
    # for all states
    req_files = files.select{|x| x.match(/sat_school_\d{4}-\d{2}\.csv/).present? }
    req_files.each do |file|
      file_name = @path + file
      list_of_hashes = @parser.parse_sat_csv(file_name)
      list_of_hashes.each do |hash|
        school_name = hash[:school_name]
        school_code = hash[:school_code]&.gsub('"',"")
        district_name = hash[:district_name]
        district_code = hash[:district_code]&.gsub('"',"")
        district_id = @keeper.get_general_id_by_district(district_name, district_code)
        hash[:general_id] = @keeper.get_general_id_by_school(school_name, school_code, district_id)

        # store assement
        assement = hash.except(:school_name, :school_code, :assement_by_levels, :district_name, :district_code)
        assement_id = @keeper.store_school_assesments(assement)
        
        assement_by_levels = hash[:assement_by_levels]
        assement_by_levels.each do |h|
          h[:assessment_id] = assement_id
        end

        @keeper.store_schools_assesments_by_level(assement_by_levels)
      end
    end

    # for state of connecticut
    req_files = files.select{|x| x.match(/sat_for_state_of_connecticut\d{4}-\d{2}\.csv/).present? }
    req_files.each do |file|
      file_name = @path + file
      list_of_hashes = @parser.parse_sat_csv(file_name)
      list_of_hashes.each do |hash|
        hash['general_id'] = @keeper.get_general_id_by_name("State of Connecticut")
        
        assement = hash.except(:school_name, :school_code, :assement_by_levels, :district_name, :district_code)
        assement_id = @keeper.store_school_assesments(assement)

        assement_by_levels = hash[:assement_by_levels]
        assement_by_levels.each do |h|
          h[:assessment_id] = assement_id
        end

        @keeper.store_schools_assesments_by_level(assement_by_levels)
      end
    end

    # race/ethnicity
    req_files = files.select{|x| x.match(/sat_data_aggreagated_by_race_ethnicity_\d{4}-\d{2}\.csv/).present? }
    req_files.each do |file|
      file_name = @path + file
      list_of_hashes = @parser.parse_sat_csv(file_name)
      list_of_hashes.each do |hash|
        district_code = hash[:district_code]&.gsub('"',"")
        district_name = hash[:district_name]
        hash['general_id'] = @keeper.get_general_id_by_district(district_name, district_code)
        
        assement = hash.except(:school_name, :school_code, :assement_by_levels, :district_name, :district_code)
        assement_id = @keeper.store_school_assesments(assement)
          
        assement_by_levels = hash[:assement_by_levels]
        assement_by_levels.each do |h|
          h[:assessment_id] = assement_id
        end

        @keeper.store_schools_assesments_by_level(assement_by_levels)
      end
    end
  end

  def parse_organization_information
    file_name = @path + "organization_information.csv"
    non_public_schools, districts, schools = @parser.parse_organization_information(file_name)

    non_public_schools.each do |hash|
      hash[:is_district] = 0
    end
    @keeper.store_general_info(non_public_schools)

    districts.each do |hash|
      hash[:is_district] = 1
    end
    @keeper.store_general_info(districts)

    schools.each do |hash|
      hash[:is_district] = 0
      hash[:district_id] = @keeper.get_general_id_by_district_name_prime(hash[:name])
    end

    @keeper.store_general_info(schools)
  end

  def parse_performance_index
    files = peon.list()
    req_files = files.select{|x| x.match(/perfomance_index_\d{4}-\d{2}\.csv/).present? }
    req_files.each do |file|
      file_name = @path + file
      list_of_hashes = @parser.parse_performance_index_csv(file_name)
      list_of_hashes.each do |hash|
        school_code = hash[:school_code]&.gsub('"',"")
        school_name = hash[:school_name]
        district_code = hash[:district_code]&.gsub('"',"")
        district_name = hash[:district_name]
        district_id = @keeper.get_general_id_by_district(district_name, district_code)
        hash['general_id'] = @keeper.get_general_id_by_school(school_name, school_code, district_id)
      end
      list_of_hashes = list_of_hashes.map{|hash| hash.except(:school_code, :school_name, :district_code, :district_name)}
      @keeper.store_schools_assesment_ssa_index(list_of_hashes)
    end
  end

  def district_expenditures
    files = peon.list()
    req_files = files.select{|x| x.match(/pupil_expenditures_\d{4}-\d{2}\.csv/).present? }
    req_files.each do |file|
      file_name = @path + file
      list_of_hashes = @parser.parse_per_pupil_expenditures_by_function_district(file_name)
      list_of_hashes.each do |hash|
        district_code = hash[:district_code]&.gsub('"',"")
        district_name = hash[:district_name]
        hash['general_id'] = @keeper.get_general_id_by_district(district_name, district_code)
      end
      list_of_hashes = list_of_hashes.map{|hash| hash.except(:district_name, :district_code)}
      @keeper.store_district_expenditures(list_of_hashes)
    end
  end

  def parse_enrollment
    files = peon.list()
    req_files = files.select{|x| x.match(/enrollment_\d{4}-\d{2}\.csv/).present? }
    req_files.each do |file|
      file_name = @path + file
      list_of_hashes = @parser.parse_enrollment_csv(file_name)
      list_of_hashes.each do |hash|
        school_name = hash[:school_name]
        school_code = hash[:school_code]&.gsub('"',"")
        district_name = hash[:district_name]
        district_code = hash[:district_code]&.gsub('"',"")
        district_id = @keeper.get_general_id_by_district(district_name, district_code)
        hash[:general_id] = @keeper.get_general_id_by_school(school_name, school_code, district_id)
      end
      list_of_hashes = list_of_hashes.map{|hash| hash.except(:school_code, :school_name, :district_code, :district_name)}
      # store list of hashes
      @keeper.store_enrollments(list_of_hashes)
    end
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

end
