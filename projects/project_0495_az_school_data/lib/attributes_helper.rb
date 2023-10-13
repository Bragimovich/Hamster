module AttributesHelper
  def az_assessment_columns
    AzAssessment.column_names
  end

  def az_enrollment_columns
    AzEnrollment.column_names
  end

  def az_dropout_columns
    AzDropout.column_names
  end

  def az_cohort_columns
    AzCohort.column_names
  end

  def sheets_ignore_list
    ['Data Dictionary', 'Subgroup Data Dictionary', 'Report Introduction', 'Read Me Navigation']
  end

  def sheets_for_assessment_data
    ['School', 'District', 'County', 'State']
  end

  def sheets_for_enrollment_data
    ['School by Grade', 'School by Gender', 'School by Ethnicity', 'School by Subgroup', 'LEA by Grade', 'LEA by Gender', 'LEA by Ethnicity', 'LEA by Subgroup', 'County by Grade', 'County by Ethnicity', 'County by Subgroup', 'Type by Grade', 'Type by Gender', 'Type by Ethnicity', 'Type by Subgroup']
  end

  def sheets_for_dropout_data
    ['School by Subgroup', 'LEA by Subgroup', 'County by Subgroup', 'State by Subgroup']
  end

  def sheets_for_cohort_data
    ['School by Subgroup', 'LEA by Subgroup', 'County by Subgroup', 'State by Subgroup']
  end


  # Params for generating md5 hash

  def assessment_key_params
    ['year', 'fiscal_year', 'school_type', 'school_entity_id', 'school_name', 'school_ctds_num', 'charter', 'alternative_school', 'district_name', 'district_entity_id', 'district_ctds_num', 'district', 'county', 'test_level', 'subgroup', 'fay_status', 'subject', 'number_tested', 'percent_passing', 'percent_proficiency_level_1', 'percent_proficiency_level_2', 'percent_proficiency_level_3', 'percent_proficiency_level_4', 'data_type']
  end

  def enrollment_key_params
    ['fiscal_year', 'school_year', 'lea_entity_id', 'lea_name', 'school_id', 'school', 'school_type', 'county', 'subgroup', 'asian', 'american_indian_alaskan_native', 'black_african_american', 'hispanic_latino', 'white', 'native_hawaiian_pacific_islander', 'missing_ethnicity', 'multiple_races', 'female', 'male', 'ps', 'kg', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', 'total', 'data_type']
  end

  def dropout_key_params
    ['year', 'lea_entity_id', 'lea_name', 'school_id', 'school', 'county', 'charter', 'subgroup', 'dropout_percentage_rate', 'data_type']
  end

  def cohort_key_params
    ['year', 'graduation_rate_type', 'lea_entity_id', 'lea_name', 'school_id', 'school', 'county', 'subgroup', 'number_graduated', 'number_in_cohort', 'percent_graduated_in_4_years', 'data_type']
  end


  def header_converted(header_cells)
    # for assessment
    header_cells.map{|c| header_alias[c] || c}
  end

  def header_converted_enrollment(header_cells)
    header_cells.map{|c| header_alias_enrollment[c] || c}
  end

  def header_converted_dropout(header_cells)
    header_cells.map{|c| header_alias_dropout[c] || c}
  end

  def header_converted_cohort(header_cells)
    header_cells.map{|c| header_alias_cohort[c] || c}
  end

  def header_alias
    {
      'district_ctds' => 'district_ctds_num',
      'schoolctds' => 'school_ctds_num',
      'school_ctds' => 'school_ctds_num',
      'alternative' => 'alternative_school'
    }
  end

  def header_alias_enrollment
    {
      'school_name' => 'school',
      'american_indian_alaska_native' => 'american_indian_alaskan_native'
    }
  end

  def header_alias_dropout
    {
      'fiscal_year' => 'year',
      'school_name' => 'school',
      'school_entity_id' => 'school_id'
    }
  end

  def header_alias_cohort
    {
      'cohort_year' => 'year',
      'school_entity_id' => 'school_id',
      'school_name' => 'school'
    }
  end
end
  