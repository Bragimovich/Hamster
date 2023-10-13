class Parser
  def get_year_options_from_page(file_content)
    data = Nokogiri::HTML(file_content)
    year_option_xpath = "//select[@id='select1']/option/text()"
    data.xpath(year_option_xpath).text().split("\n")
  end

  def get_high_and_low_grade(hash)
    low_grade = nil
    high_grade = nil
    sliced_hash = hash.slice(*hash.keys[15..-1])
    if sliced_hash.values.map(&:to_i).sum > 0
      sliced_hash.keys.each do |key|
        if sliced_hash[key] == "1"
          low_grade = key
          break
        end
      end

      sliced_hash.keys.reverse.each do |key|
        if sliced_hash[key] == "1"
          high_grade = key
          break
        end
      end
    end
    [high_grade, low_grade]
  end

  def csv_parser(file_name,lines_to_skip)
    lines = File.open(file_name, "r").readlines
    lines = lines[lines_to_skip..-1]
    list = []
    lines.each do |line|
      line = line.encode("UTF-8", invalid: :replace, replace: "")
      row = CSV.parse(line.strip.gsub("=",""), quote_char: '"')
      list << row
    end
    list
  end

  def get_list_of_dicts(list)
    key = list[0][0]
    updated_keys = []

    vals_ind = 0
    vals = ["count|Level 1 Not Met", "count|Level 2 Approaching", "count|Level 3 Met", "count|Level 4 Exceeded", "count|Level 3 & 4 Met or Exceeded"]
    
    percent_ind = 0
    percent_vals = ["%|Level 1 Not Met", "%|Level 2 Approaching", "%|Level 3 Met", "%|Level 4 Exceeded", "%|Level 3 & 4 Met or Exceeded"]

    key.each do |k|
      if k == 'Count'
        updated_keys << vals[vals_ind]
        vals_ind += 1
      elsif k == '%'
        updated_keys << percent_vals[percent_ind]
        percent_ind += 1    
      else
        updated_keys << k
      end
    end

    list_of_dicts = list[1..-2].map{|val| updated_keys.zip(val[0]).to_h}
  end

  def parse_performance_index_csv(file_name)
    list = csv_parser(file_name, 9)
    list_of_dicts = get_list_of_dicts(list)

    list_of_hashes = []
    list_of_dicts.each do |hash|

      temp = {
        district_name: hash['District Name'],
        district_code: hash['District Code'],
        school_code: hash['School Code'],
        school_name: hash['School Name'],
        group: hash['Student Group'],
        category: hash['Category'],
        data_source_url: "https://public-edsight.ct.gov/performance/performance-index?language=en_US",
        school_year: _parse_school_year(file_name.match(/\d{4}-\d{2}/).to_s),
      }

      ela_subject = {
        count: hash['ELACount'],
        subject: 'ELA',
        performance_index: hash['ELAPerformanceIndex'],
      }

      math_subject = {
        count: hash['MathCount'],
        subject: 'Math',
        performance_index: hash['MathPerformanceIndex']
      }

      science_subject = {
        count: hash['ScienceCount'],
        subject: 'Science',
        performance_index: hash['SciencePerformanceIndex'],
      }

      list_of_hashes << science_subject.merge(temp)
      list_of_hashes << math_subject.merge(temp)
      list_of_hashes << ela_subject.merge(temp)
    end

    list_of_hashes
  end

  def parse_per_pupil_expenditures_by_function_district(file_name)
    list = csv_parser(file_name, 9)
    list_of_dicts = get_list_of_dicts(list)

    list_of_hashes = []
    list_of_dicts.each do |hash|
      temp = {
        district_name: hash['District'],
        district_code: hash['District Code'],
        function: hash['Function'],
        expenditures: hash['Expenditures'],
        pupils: hash['Pupils'],
        pupil_basis: hash['Pupil Basis'],
        expenditures_per_pupil: hash['PPE'],
        data_source_url: "https://public-edsight.ct.gov/overview/per-pupil-expenditures-by-function---district?language=en_US",
        school_year: _parse_school_year(file_name.match(/\d{4}-\d{2}/).to_s)
      }
      list_of_hashes << temp
    end
    list_of_hashes
  end

  def parse_enrollment_csv(file_name)
    list = csv_parser(file_name, 5)
    list_of_dicts = get_list_of_dicts(list)
    keys_to_make_header_as_value = list_of_dicts[0].keys[4..-1]
    list_of_hashes = []
    list_of_dicts.each do |hash|
      temp = {
        grade: 'TOTAL',
        school_year: _parse_school_year(file_name.match(/\d{4}-\d{2}/).to_s),
        data_source_url: 'https://public-edsight.ct.gov/Students/Enrollment-Dashboard/Enrollment-Report-Legacy?language=en_US',
        school_code: hash['School Code'],
        school_name: hash['School'],
        district_code: hash['District Code'],
        district_name: hash['District']
      }
      keys_to_make_header_as_value.each do |k|
        temp[:demographic] = k
        temp[:count] = hash[k]
        list_of_hashes << temp.clone
      end
    end
    list_of_hashes
  end

  def parse_smarter_balanced_csv(file_name)
    list = csv_parser(file_name, 4)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    
    list_of_dicts.each do |hash|
      temp = {
        district_name: hash['District'],
        school_name: hash['School'],
        school_code: hash['School Code'],
        demographic: 'TOTAL', 
        school_year: _parse_school_year(file_name.match(/\d{4}-\d{2}/).to_s),
        exam_name: 'Smarter Balanced',
        subject: hash['Subject'],
        grade: hash['Grade'],
        number_of_students: hash['Total Number of Students'],
        number_tested: hash['Total Number Tested'],
        rate_percent: hash['Smarter Balanced Participation Rate'],
        with_scored: hash['Total Number with Scored Tests'],
        average_score: hash['Average VSS'],
        data_source_url: 'https://public-edsight.ct.gov/performance/smarter-balanced-achievement-participation?language=en_US'
      }

      result_in_levels = []
      sat_mapping.each do |percent , count|
        _temp = {
          level: percent.split("|")[-1],
          count: hash[count],
          percent: hash[percent],
          data_source_url: 'https://public-edsight.ct.gov/performance/smarter-balanced-achievement-participation?language=en_US'
        }
        result_in_levels << _temp
      end

      temp[:assement_by_levels] = result_in_levels
      list_of_hashes << temp
    end
    list_of_hashes
  end

  def parse_sat_csv(file_name)
    list = csv_parser(file_name, 4)
    list_of_dicts = get_list_of_dicts(list)
    list_of_hashes = []
    
    list_of_dicts.each do |hash|
      temp = {
        district_name: hash['District'],
        district_code: hash['District Code'],
        school_name: hash['School'],
        school_code: hash['School Code'],
        grade: 'TOTAL',
        demographic: hash['Race/Ethnicity'] ||= 'TOTAL', 
        school_year: _parse_school_year(file_name.match(/\d{4}-\d{2}/).to_s),
        exam_name: 'Scholastic Aptitude Test',
        subject: hash['Subject'],
        number_of_students: hash['Total Numberof Students'],
        number_tested: hash['Total NumberTested'],
        rate_percent: hash['CT School Day SATParticipationRate'],
        with_scored: hash['Total Numberwith Scored Tests'],
        average_score: hash['AverageScore'],
        data_source_url: 'https://public-edsight.ct.gov/performance/connecticut-school-day-sat?language=en_US' 
      }

      result_in_levels = []
      sat_mapping.each do |percent , count|
        temp_assesment_level = {
          level: percent.split("|")[-1],
          count: hash[count],
          percent: hash[percent],
          data_source_url: 'https://public-edsight.ct.gov/performance/connecticut-school-day-sat?language=en_US'
        }
        result_in_levels << temp_assesment_level
      end
      temp[:assement_by_levels] = result_in_levels
      list_of_hashes << temp
    end
    list_of_hashes
  end

  def sat_mapping
    vals = ["count|Level 1 Not Met", "count|Level 2 Approaching", "count|Level 3 Met", "count|Level 4 Exceeded", "count|Level 3 & 4 Met or Exceeded"]
    percent_vals = ["%|Level 1 Not Met", "%|Level 2 Approaching", "%|Level 3 Met", "%|Level 4 Exceeded", "%|Level 3 & 4 Met or Exceeded"]
    percent_vals.zip(vals)
  end

  def parse_next_generation_science_standards(file_name)
    list = csv_parser(file_name, 4)
    list_of_dicts = get_list_of_dicts(list)

    list_of_hashes = []
    list_of_dicts.each do |hash|
      temp = {
        district_name: hash['District'],
        district_code: hash['District Code'],
        school_name: hash['School'],
        school_code: hash['School Code'],
        demographic: 'TOTAL',
        subject: 'TOTAL',
        school_year: _parse_school_year(file_name.match(/\d{4}-\d{2}/).to_s),
        exam_name: 'Next Generation Science Standarts',
        grade: hash['Grade'] ||= 'TOTAL',
        number_of_students: hash['Total Number of Students'],
        number_tested: hash['Total Number Tested'],
        rate_percent: hash['NGSS Participation Rate'],
        with_scored: hash['Total Number with Scored Tests'],
        average_score: hash['AverageScale Score (SS)'],
        data_source_url: 'https://public-edsight.ct.gov/performance/ngss-assessment?language=en_US'
      }

      result_in_levels = []
      sat_mapping.each do |percent , count|
        _temp = {
          level: percent.split("|")[-1],
          count: hash[count],
          percent: hash[percent],
          data_source_url: 'https://public-edsight.ct.gov/performance/ngss-assessment?language=en_US'
        }
        result_in_levels << _temp
      end
      temp[:assement_by_levels] = result_in_levels
      list_of_hashes << temp
    end
    list_of_hashes
  end

  def parse_organization_information(file_name)
    list = csv_parser(file_name, 3)
    list_of_dicts = get_list_of_dicts(list)
    non_public_schools = map_organization_information_hashes(list_of_dicts.select{|x| x["District"] == nil})
    districts = map_organization_information_hashes(list_of_dicts.select{|x| x["District"] == x["OrganizationName"] })
    schools = map_organization_information_hashes(list_of_dicts.select{|x| x["District"] != x["OrganizationName"] && x["District"] != nil })
    [non_public_schools, districts, schools]
  end

  def map_organization_information_hashes(list_of_hashes)
    mapped_list_of_hashes = []
    list_of_hashes.each do |hash|
      high_grade, low_grade = get_high_and_low_grade(hash)
      temp = {
        name: hash['OrganizationName'],
        number: hash['OrganizationCode'],
        nces_id: hash['NCES Code'],
        type: hash['OrganizationType'],
        program_type: hash['Program Type'],
        education_program: hash['Education Program'],
        phone: hash['Phone'],
        fax: hash['Fax'],
        website: hash['Website'],
        address: hash['Street'],
        city: hash['City'],
        state: hash['State'],
        zip: hash['ZIP'],
        low_grade: low_grade,
        high_grade: high_grade,
        data_source_url: 'https://public-edsight.ct.gov/overview/find-schools?language=en_US'
      }
      mapped_list_of_hashes << temp
    end
    mapped_list_of_hashes
  end

  def _parse_school_year(year)
    regex_pattren = /\d{4}-\d{2}$/
    if year.match(regex_pattren)
      year.insert(5,"20")
    end
    year
  end

end
