class Parser
  def zip_file_links(response_body, download_type)
    zip_links = []
    parsed_page = Nokogiri::HTML(response_body)
    a_tags = parsed_page.xpath("//span[@class='file']/a")
    case download_type
    when 'Enrollment'
      a_tags.each do |a_tag|
        file_name = a_tag.text
        file_url = a_tag.at_xpath("./@href").value
        zip_links << {name: file_name, url: file_url} if file_name.match(/gradelevel_certified/)
      end
    when 'Attendance'
      a_tags.each do |a_tag|
        file_name = a_tag.text
        file_url = a_tag.at_xpath("./@href").value
        zip_links << {name: file_name, url: file_url} if file_name.match(/attendance_dropouts/)
      end
    else
      zip_links = a_tags.map{|a_tag| {name: a_tag.text, url: a_tag.at_xpath("./@href").value}}
    end
    zip_links
  end

  def parse_enrollment_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      grade: row['GRADE_LEVEL'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      subgroup_count: row['GROUP_COUNT'],
      students_count: row['STUDENT_COUNT'],
      students_percent: row['PERCENT_OF_GROUP'],
      data_source_url: data_source
    }
    hash_data
  end

  def parse_wsas_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      subject: row['TEST_SUBJECT'],
      grade: row['GRADE_LEVEL'],
      test_result: row['TEST_RESULT'],
      test_result_code: row['TEST_RESULT_CODE'],
      test: row['TEST_GROUP'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      student_count: row['STUDENT_COUNT'],
      subgroup_percent: row['PERCENT_OF_GROUP'],
      subgroup_count: row['GROUP_COUNT'],
      scale_score_avg: row['WKCE_AVERAGE_SCALE_SCORE'],
      data_source_url: data_source
    }
    hash_data
  end

  def parse_act11_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      subject: row['TEST_SUBJECT'],
      test_result: row['TEST_RESULT'],
      test_result_code: row['TEST_RESULT_CODE'],
      college_readiness: row['COLLEGE_READINESS'],
      test: row['TEST_GROUP'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      student_count: row['STUDENT_COUNT'],
      score_avg: row['AVERAGE_SCORE'],
      subgroup_count: row['GROUP_COUNT'],
      data_source_url: data_source
    }
    hash_data
  end

  def parse_act_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      subject: row['TEST_SUBJECT'],
      college_readiness: row['COLLEGE_READINESS'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      student_count: row['STUDENT_COUNT'],
      score_avg: row['AVERAGE_SCORE'],
      subgroup_count: row['GROUP_COUNT'],
      data_source_url: data_source
    }
    hash_data
  end

  def parse_aspire_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      subject: row['TEST_SUBJECT'],
      grade: row['GRADE_LEVEL'],
      test_result: row['TEST_RESULT'],
      test_result_code: row['TEST_RESULT_CODE'],
      test: row['TEST_GROUP'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      student_count: row['STUDENT_COUNT'],
      subgroup_count: row['GROUP_COUNT'],
      score_avg: row['AVERAGE_SCORE'],
      data_source_url: data_source
    }
    hash_data
  end

  def parse_forward_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      subject: row['TEST_SUBJECT'],
      grade: row['GRADE_LEVEL'],
      test_result: row['TEST_RESULT'],
      test_result_code: row['TEST_RESULT_CODE'],
      test: row['TEST_GROUP'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      student_count: row['STUDENT_COUNT'],
      subgroup_percent: row['PERCENT_OF_GROUP'],
      subgroup_count: row['GROUP_COUNT'],
      score_avg: row['FORWARD_AVERAGE_SCALE_SCORE'],
      data_source_url: data_source
    }
    hash_data
  end
  
  def parse_discipline_actions_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      removal_type_desc: row['REMOVAL_TYPE_DESCRIPTION'],
      tfs_enrollment_count: row['TFS_ENROLLMENT_COUNT'],
      removal_count: row['REMOVAL_COUNT'],
      data_source_url: data_source
    }
    hash_data
  end

  def parse_discipline_incidents_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      behavior_type: row['BEHAVIOR_TYPE'],
      tfs_enrollment_count: row['TFS_ENROLLMENT_COUNT'],
      incidents_count: row['INCIDENTS_COUNT'],
      data_source_url: data_source
    }
    hash_data
  end

  def parse_attendance_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      student_count: row['STUDENT_COUNT'],
      possible_days_of_attendance: row['POSSIBLE_DAYS_OF_ATTENDANCE'],
      actual_days_of_attendance: row['ACTUAL_DAYS_OF_ATTENDANCE'],
      attendance_rate: row['ATTENDANCE_RATE'],
      data_source_url: data_source
    }
    hash_data
  end

  def parse_dropout_csv(row, data_source)
    hash_data = {
      school_year: row['SCHOOL_YEAR'],
      subgroup: row['GROUP_BY'],
      demographic: row['GROUP_BY_VALUE'],
      student_count: row['STUDENT_COUNT'],
      dropout_count: row['DROPOUT_COUNT'],
      completed_term_count: row['COMPLETED_TERM_COUNT'],
      dropout_rate: row['DROPOUT_RATE'],
      data_source_url: data_source
    }
    hash_data
  end
end
