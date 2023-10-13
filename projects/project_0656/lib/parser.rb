# frozen_string_literal: true
require 'roo'
require 'roo-xls'

class Parser < Hamster::Parser

  def initialize_values(ids_and_numbers, ids_and_names, run_id)
    @info_ids_and_numbers = ids_and_numbers
    @info_ids_and_names = ids_and_names
    @run_id = run_id
  end

  def get_grad_and_assesment_files_links(response)
    page = parse_page(response)
    grad_links = page.css('a').select{ |e| e['href'].include? 'gradrate' }.map{ |e| e['href'] }
    assessment_links = page.css('a').select{ |e| e['href'].include? 'assessment' }.map{ |e| e['href'] }
    [grad_links,assessment_links]
  end

  def get_nyc_and_ros_links(response)
    page = parse_page(response)
    links_array = []
    keys = ['NYC','ROS','RESTOFSTATE','Rest_of_State','2017_New_York_City_DASA']
    keys.each do |key|
      links_array << get_clean_links(page, key)
    end
    links_array.flatten.uniq
  end

  def get_salaries_links(response)
    page = parse_page(response)
    links = page.css('#content_column ul a').map{ |e| e['href'] }
    links.map{ |e| e.gsub('https://www.p12.nysed.gov/mgtserv/admincomp/', '') }
  end

  def get_enrollment_links(response)
    page = parse_page(response)
    links = page.css('#content_column a').map{ |e| e['href'] }
    links.reject { |e| e.include? 'html' }
  end

  def parse_enrollment_data(file)
    data_array = []
    rows = parse_excel_file(file)
    return [] if (rows.nil?)
    headers = rows.first.map{ |e| e.downcase }
    headers = nil unless (headers.include? 'state district id')
    pk12_index = headers.index(headers.select{ |e| e.to_s.downcase.include? 'pk12' }.first)
    grades = headers[pk12_index..]
    return [] if (headers.nil?)
    rows.each_with_index do |row,index|
      next if (index == 0)
      grades.each do |grade|
        location_id = get_row_value(row, headers, 'state location id')
        state_id = get_row_value(row, headers, 'state district id')
        general_id = get_general_id(location_id)
        general_id = get_general_id(state_id) if (general_id.nil?)
        school_year = get_row_value(row, headers, 'school year')
        data_hash = {}
        data_hash[:general_id]     = general_id
        data_hash[:school_year]    = get_required_school_year(school_year)
        data_hash[:group]          = get_group_name(file)
        data_hash[:subgroup]       = get_row_value(row, headers , 'subgroup name')
        data_hash[:grade]          = grade.upcase
        data_hash[:count]          = get_row_value(row, headers, grade)
        data_hash[:run_id]         = run_id
        data_hash[:touched_run_id] = run_id
        data_hash                  = mark_empty_as_nil(data_hash)
        data_array << data_hash
      end
    end
    data_array.reject{ |e| e[:general_id].nil? }
  end

  def parse_graduation_data(file)
    data_array = []
    rows = parse_csv_file(file)
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      next if (index == 0)
      aggr_code = get_row_value(row, headers, 'aggregation_code')
      lea_bed = get_row_value(row, headers, 'lea_beds')
      data_hash = {}
      data_hash[:general_id]                     = get_general_id(aggr_code)
      data_hash[:general_id]                     = get_general_id(lea_bed) if (data_hash[:general_id].nil?)
      data_hash[:school_year]                    = get_required_school_year(get_row_value(row, headers, 'report_school_year'))
      data_hash[:membership_code]                = get_row_value(row, headers, 'membership_code')
      data_hash[:membership_key]                 = get_row_value(row, headers, 'membership_key')
      data_hash[:membership_desc]                = get_row_value(row, headers, 'membership_desc')
      data_hash[:subgroup_code]                  = get_row_value(row, headers, 'subgroup_code')
      data_hash[:subgroup]                       = get_row_value(row, headers, 'subgroup_name')
      data_hash[:enroll_count]                   = get_row_value(row, headers, 'enroll_cnt')
      data_hash[:grad_count]                     = get_row_value(row, headers, 'grad_cnt')
      data_hash[:grad_percent]                   = get_row_value(row, headers, 'grad_pct')
      data_hash[:local_count]                    = get_row_value(row, headers, 'local_cnt')
      data_hash[:local_percent]                  = get_row_value(row, headers, 'local_pct')
      data_hash[:reg_count]                      = get_row_value(row, headers, 'reg_cnt')
      data_hash[:reg_percent]                    = get_row_value(row, headers, 'reg_pct')
      data_hash[:reg_adv_count]                  = get_row_value(row, headers, 'reg_adv_cnt')
      data_hash[:reg_adv_percent]                = get_row_value(row, headers, 'reg_adv_pct')
      data_hash[:non_diploma_credential_count]   = get_row_value(row, headers, 'non_diploma_credential_cnt')
      data_hash[:non_diploma_credential_percent] = get_row_value(row, headers, 'non_diploma_credential_pct')
      data_hash[:still_enr_count]                = get_row_value(row, headers, 'still_enr_cnt')
      data_hash[:still_enr_percent]              = get_row_value(row, headers, 'still_enr_pct')
      data_hash[:ged_count]                      = get_row_value(row, headers, 'ged_cnt')
      data_hash[:ged_percent]                    = get_row_value(row, headers, 'ged_pct')
      data_hash[:dropout_count]                  = get_row_value(row, headers, 'dropout_cnt')
      data_hash[:dropout_percent]                = get_row_value(row, headers, 'dropout_pct')
      data_hash[:run_id]                         = run_id
      data_hash[:touched_run_id]                 = run_id
      data_hash                                  = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array.reject{ |e| e[:general_id].nil? }
  end

  def parse_expenditure_data(file)
    data_array = []
    rows = parse_csv_file(file)
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      next if (index == 0)
      entity_cd = get_row_value(row, headers, 'entity_cd')
      school_year = get_row_value(row, headers, 'year')
      school_year = "#{school_year.to_i - 1}-#{school_year}"
      data_hash = {}
      data_hash[:general_id]                  = get_general_id(entity_cd)
      data_hash[:pupil_count_total]           = get_row_value(row, headers, 'pupil_count_tot')
      data_hash[:federal_count]               = get_row_value(row, headers, 'federal_exp')
      data_hash[:federal_percent]             = get_row_value(row, headers, 'per_federal_exp')
      data_hash[:state_local_count]           = get_row_value(row, headers, 'state_local_exp')
      data_hash[:state_local_percent]         = get_row_value(row, headers, 'per_state_local_exp')
      data_hash[:federal_state_local_count]   = get_row_value(row, headers, 'fed_state_local_exp')
      data_hash[:federal_state_local_percent] = get_row_value(row, headers, 'per_fed_state_local_exp')
      data_hash[:data_reported_enr]           = get_row_value(row, headers, 'data_reported_enr')
      data_hash[:data_reported_exp]           = get_row_value(row, headers, 'data_reported_exp')
      data_hash[:md5_hash]                    = create_md5_hash(data_hash)
      data_hash[:school_year]                 = school_year
      data_hash[:run_id]                      = run_id
      data_hash[:touched_run_id]              = run_id
      data_hash[:data_source_url]             = 'https://data.nysed.gov/downloads.php'
      data_hash                               = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array.reject{ |e| e[:general_id].nil? }
  end

  def parse_absenteeism_data(file)
    data_array = []
    rows = parse_csv_file(file)
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      next if (index == 0)
      entity_cd = get_row_value(row, headers, 'entity_cd')
      school_year = get_row_value(row, headers, 'year')
      school_year = "#{school_year.to_i - 1}-#{school_year}"
      data_hash = {}
      data_hash[:general_id]      = get_general_id(entity_cd)
      data_hash[:subject]         = get_row_value(row, headers, 'subject')
      data_hash[:subgroup]        = get_row_value(row, headers, 'subgroup_name')
      data_hash[:enrollment]      = get_row_value(row, headers, 'enrollment')
      data_hash[:absent_count]    = get_row_value(row, headers, 'absent_count')
      data_hash[:absent_rate]     = get_row_value(row, headers, 'absent_rate')
      data_hash[:level]           = get_row_value(row, headers, 'level')
      data_hash[:override]        = get_row_value(row, headers, 'override')
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:school_year]     = school_year
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_hash[:data_source_url] = 'https://data.nysed.gov/downloads.php'
      data_hash                   = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array.reject{ |e| e[:general_id].nil? }
  end

  def parse_elp_data(file)
    data_array = []
    rows = parse_csv_file(file)
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      next if (index == 0)
      entity_cd = get_row_value(row, headers, 'entity_cd')
      school_year = get_row_value(row, headers, 'year')
      school_year = "#{school_year.to_i - 1}-#{school_year}"
      data_hash = {}
      data_hash[:general_id]      = get_general_id(entity_cd)
      data_hash[:subject]         = get_row_value(row, headers, 'subject')
      data_hash[:subgroup]        = get_row_value(row, headers, 'subgroup_name')
      data_hash[:ell_count]       = get_row_value(row, headers, 'ell_count')
      data_hash[:benchmark]       = get_row_value(row, headers, 'benchmark')
      data_hash[:progress_rate]   = get_row_value(row, headers, 'progress_rate')
      data_hash[:success_ratio]   = get_row_value(row, headers, 'success_ratio')
      data_hash[:level]           = get_row_value(row, headers, 'level')
      data_hash[:override]        = get_row_value(row, headers, 'override')
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:school_year]     = school_year
      data_hash[:run_id]          = run_id
      data_hash[:touched_run_id]  = run_id
      data_hash[:data_source_url] = 'https://data.nysed.gov/downloads.php'
      data_hash                   = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array.reject{ |e| e[:general_id].nil? }
  end

  def parse_regent_data(file)
    data_array = []
    rows = parse_csv_file(file)
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      next if (index == 0)
      entity_cd = get_row_value(row, headers, 'entity_cd')
      school_year = get_row_value(row, headers, 'year')
      school_year = "#{school_year.to_i - 1}-#{school_year}"
      data_hash = {}
      data_hash[:general_id]         = get_general_id(entity_cd)
      data_hash[:subject]            = get_row_value(row, headers, 'subject')
      data_hash[:subgroup]           = get_row_value(row, headers, 'subgroup_name')
      data_hash[:total_tested]       = get_row_value(row, headers, 'tested')
      data_hash[:l1_count]           = get_row_value(row, headers, 'num_level1')
      data_hash[:l1_percent]         = get_row_value(row, headers, 'per_level1')
      data_hash[:l2_count]           = get_row_value(row, headers, 'num_level2')
      data_hash[:l2_percent]         = get_row_value(row, headers, 'per_level2')
      data_hash[:l3_count]           = get_row_value(row, headers, 'num_level3')
      data_hash[:l3_percent]         = get_row_value(row, headers, 'per_level3')
      data_hash[:l4_count]           = get_row_value(row, headers, 'num_level4')
      data_hash[:l4_percent]         = get_row_value(row, headers, 'per_level4')
      data_hash[:l5_count]           = get_row_value(row, headers, 'num_level5')
      data_hash[:l5_percent]         = get_row_value(row, headers, 'per_level5')
      data_hash[:proficient_count]   = get_row_value(row, headers, 'num_prof')
      data_hash[:proficient_percent] = get_row_value(row, headers, 'per_prof')
      data_hash[:md5_hash]           = create_md5_hash(data_hash)
      data_hash[:school_year]        = school_year
      data_hash[:run_id]             = run_id
      data_hash[:touched_run_id]     = run_id
      data_hash[:data_source_url]    = 'https://data.nysed.gov/downloads.php'
      data_hash                      = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array.reject{ |e| e[:general_id].nil? }
  end

  def parse_assesement_data(file)
    data_array = []
    rows = parse_csv_file(file)
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      next if (index == 0)
      subject = (file.include? 'nysaa') ? get_row_value(row, headers, 'subject') : file.split('/').last.split('_')[2].upcase
      entity_cd = get_row_value(row, headers, 'entity_cd')
      school_year = get_row_value(row, headers, 'year')
      school_year = "#{school_year.to_i - 1}-#{school_year}"
      data_hash = {}
      data_hash[:general_id]           = get_general_id(entity_cd)
      data_hash[:subject]              = subject
      data_hash[:grade]                = get_row_value(row, headers, 'item_desc')
      data_hash[:subgroup_code]        = get_row_value(row, headers, 'subgroup_code')
      data_hash[:subgroup]             = get_row_value(row, headers, 'subgroup_name')
      data_hash[:total_enrolled]       = get_row_value(row, headers, 'total_count')
      data_hash[:total_not_tested]     = get_row_value(row, headers, 'not_tested')
      data_hash[:total_tested]         = get_row_value(row, headers, 'num_tested')
      data_hash[:l1_count]             = get_row_value(row, headers, 'level1_count')
      data_hash[:l1_percent]           = get_row_value(row, headers, 'level1_%tested')
      data_hash[:l2_count]             = get_row_value(row, headers, 'level2_count')
      data_hash[:l2_percent]           = get_row_value(row, headers, 'level2_%tested')
      data_hash[:l3_count]             = get_row_value(row, headers, 'level3_count')
      data_hash[:l3_percent]           = get_row_value(row, headers, 'level3_%tested')
      data_hash[:l4_count]             = get_row_value(row, headers, 'level4_count')
      data_hash[:l4_percent]           = get_row_value(row, headers, 'level4_%tested')
      data_hash[:proficient_percent]   = get_row_value(row, headers, 'per_prof')
      data_hash[:assessment]           = get_row_value(row, headers, 'assessment_name')
      data_hash[:total_not_tested_pct] = get_row_value(row, headers, 'pct_not_tested')
      data_hash[:mean_scale_score]     = get_row_value(row, headers, 'total_scale_score')
      data_hash[:total_tested_pct]     = get_row_value(row, headers, 'pct_tested')
      data_hash[:proficient_count]     = get_row_value(row, headers, 'num_prof')
      data_hash[:l5_count]             = get_row_value(row, headers, 'level5_count')
      data_hash[:l5_percent]           = get_row_value(row, headers, 'level5_%tested')
      data_hash[:total_scale_score]    = get_row_value(row, headers, 'mean_score')
      data_hash[:school_year]          = school_year
      data_hash[:run_id]               = run_id
      data_hash[:touched_run_id]       = run_id
      data_hash[:data_source_url]      = 'https://data.nysed.gov/downloads.php'
      data_hash                        = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array.reject{ |e| e[:general_id].nil? }
  end

  def parse_salaries_data(file)
    data_array = []
    year = file.split('/').last.scan(/\d+/).select{ |e| e.size == 4 }.last.to_i
    school_year = (year == 0) ? nil : "#{year}-#{year+1}" 
    rows = parse_excel_file(file)
    if (school_year.nil?)
      years_range = rows.select{ |e| e.join.downcase.include? 'admin' }.first.join.scan(/\d+/)
      school_year = "#{years_range.first}-#{years_range.last}"
    end
    headers = rows.select{ |e| e.join.downcase.include? 'other' }.first.reject{ |e| e.nil? }.map{ |e| e.downcase.squish }
    rows.each_with_index do |row,index|
      next if (check_required_data(row, 'other') || check_required_data(row, 'admin') || check_required_data(row, 'last'))
      next if (row.join.scan(/\d/).count < 8)
      district_name = get_row_value(row, headers, 'name')
      data_hash = {}
      data_hash[:general_id]     = get_salaries_general_id(district_name)
      data_hash[:general_id]     = data_array.last[:general_id] if (data_hash[:general_id].nil?) rescue nil
      data_hash[:school_year]    = school_year
      data_hash[:type]           = get_row_value(row, headers, 'type')
      data_hash[:type]           = get_row_value(row, headers, 'item').to_i if (data_hash[:type].nil?)
      data_hash[:title]          = get_row_value(row, headers, 'title')
      data_hash[:salary]         = get_row_value(row, headers, 'salary')
      data_hash[:benefits]       = get_row_value(row, headers, 'benefits')
      data_hash[:other]          = get_row_value(row, headers, 'other')
      data_hash[:total]          = get_row_value(row, headers, 'total')
      data_hash[:total]          = get_total_value(data_hash) if (data_hash[:total].nil?)
      data_hash[:run_id]         = run_id
      data_hash[:touched_run_id] = run_id
      data_hash                  = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array.reject{ |e| e[:general_id].nil? }
  end

  def parse_safety_data(file)
    data_array = []
    rows = parse_excel_file(file)
    years_range = rows.first.join.scan(/\d+/)
    start_year = years_range.first
    end_year = (years_range[1].size == 2) ? "20#{years_range[1]}" : years_range[1]
    school_year = "#{start_year}-#{end_year}"
    headers = rows.select{ |e| e.join.downcase.include? 'county' }.first.reject{ |e| e.nil? }.map{ |e| e.downcase.squish }
    file = file.split('/').last
    nyc_value = ((file.downcase.include? 'nyc') || (file.downcase.include? 'york')) ? 1 : 0
    case
    when check_headers_condition(headers, 'nature')
      incident_domain = headers.last.gsub('nature of material','').strip
      incident_domain = "#{incident_domain} by"
      incidents_list = rows.select{ |e| e.join.downcase.include? 'race' }.first.reject{ |e| e.nil? }.map{ |e| e.downcase.squish }
    when check_headers_condition(headers, 'inactive')
      incident_domain = ""
      inactive_index = headers.index(headers.select{ |e| e.include? 'inactive' }.first)
      incidents_list = headers[inactive_index + 1..]
    else
      incidents_list = []
      domain_index = headers.index(headers.select{ |e| e.include? 'homicide' }.first)
      incident_domain = headers[domain_index..]
      incidents = rows.select{ |e| e.join.downcase.include? 'without'}.first
      weapon_index = incidents.index("With Weapon(s)")
      incidents = incidents[weapon_index..]
      domain_index = 0
      incidents.each_with_index do |incident,index|
        next if (check_incident_condition(incident, 'without') || check_incident_condition(incident, 'under'))
        case
        when (incident.nil?)
          incidents_list << incident_domain[domain_index]
          domain_index += 1
        else
          incidents_list << "#{incident_domain[domain_index]} #{incident}"
          incidents_list << "#{incident_domain[domain_index]} #{incidents[index + 1]}"
          domain_index += 1
        end
      end
      incidents_list = incidents_list.uniq
      incident_domain = ""
    end
    rows.each_with_index do |row,index|
      next if (row.join.scan(/\d/).count < 12)
      data_array << get_safety_data_hash(row, headers, incident_domain, incidents_list, school_year, nyc_value)
    end
    data_array.flatten.reject{ |e| e[:general_id].nil? }
  end

  def convert_tab_to_csv(file)
    output_file = file.gsub('tab','csv')
    CSV.open(output_file, "wb") do |csv_output|
      CSV.foreach(file, col_sep: "\t") do |row|
        csv_output << row
      end
    end
  end

  def convert_excel_to_csv(file)
    xlsx_file = Roo::Spreadsheet.open(file)
    output_file = file.gsub('xlsx','csv')
    csv = File.open(output_file, 'w')
    xlsx_file.each_row_streaming do |row|
      csv.write(row.map(&:value).join(","))
      csv.write("\n")
    end
  end

  private

  attr_reader :info_ids_and_numbers, :run_id, :info_ids_and_names

  def get_required_school_year(school_year)
    begin
      school_year.sub(/(\d{4})-(\d{2})/, '\1-20\2')
    rescue
      school_year
    end
  end

  def get_safety_data_hash(row, headers, incident_domain, incidents_list, school_year, nyc_value)
    data_array = []
    incidents_list.each_with_index do |incident,index|
      beds_code = get_row_value(row, headers, 'beds')
      data_hash = {}
      data_hash[:general_id]     = get_general_id(beds_code)
      data_hash[:school_year]    = school_year
      data_hash[:incident]       = "#{incident_domain} #{incident}".squish
      data_hash[:count]          = row[index - incidents_list.count]
      data_hash[:nyc]            = nyc_value
      data_hash[:run_id]         = run_id
      data_hash[:touched_run_id] = run_id
      data_hash                  = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array
  end

  def check_headers_condition(headers, key)
    return true if (headers.join.include? key)
    false
  end

  def check_incident_condition(incident, key)
    return true if (incident.to_s.downcase.include? key)
    false
  end

  def get_group_name(file)
    case
    when check_file_name(file, 'lep')
      "English Language Learners"
    when check_file_name(file, 'swd')
      "Students with Disabilities"
    when check_file_name(file, 'race')
      "Race and Ethnic Origin"
    when check_file_name(file, 'gender')
      "Gender"
    when check_file_name(file, 'econ')
      "Economically Disadvantaged"
    when check_file_name(file, 'allstudents')
      "All Students"
    end
  end

  def get_total_value(data_hash)
    salary = get_integer_value(data_hash[:salary])
    benefits = get_integer_value(data_hash[:benefits])
    other = get_integer_value(data_hash[:other])
    "$#{salary + benefits + other}"
  end

  def get_integer_value(value)
    (value.nil?) ? 0 : value.to_s.gsub('$','').squish.to_f
  end

  def check_required_data(row, key)
    return true if (row.join.downcase.include? key)
  end

  def get_asses_school_year(file)
    school_end_year = file.split('.').first.split('_').last.to_i
    "#{school_end_year - 1}-#{school_end_year}"
  end

  def check_file_name(file, key)
    return true if (file.downcase.include? key)
    false
  end

  def get_row_value(row, headers ,key)
    value_index = headers.index(headers.select{ |e| e.include? key }.first)
    row[value_index] unless value_index.nil?
  end

  def get_general_id(key)
    required_array = info_ids_and_numbers.select{ |e| e.last == key }.first
    required_array.first unless required_array.nil?
  end

  def get_salaries_general_id(key)
    unless key.nil?
      required_array = info_ids_and_names.select{ |e| e.last.downcase.include? key.split[0...-1].join(' ').downcase }.first
      required_array.first unless required_array.nil?
    else
      nil
    end
  end

  def get_clean_links(page, key)
    links = page.css('a').select{ |e| e['href'].include? key }
    links = links.map{ |e| e['href'].gsub('https://www.p12.nysed.gov/irs/school_safety/', '') }
    links.map{ |e| "/irs/school_safety/#{e}" }
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def parse_excel_file(file)
    begin
      doc = (file.include? 'xlsx') ? Roo::Spreadsheet.open(file) : Roo::Excel.new(file)
      (doc.sheets.count > 1) ? doc.sheet(doc.sheets[1]) : doc.sheet(doc.default_sheet)
    rescue
      nil
    end
  end

  def parse_csv_file(file)
    CSV.foreach(file)
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

end
