# frozen_string_literal: true
require 'roo'
require 'roo-xls'

class Parser < Hamster::Parser

  def initialize_values(ids_and_numbers, ids_and_numbers_with_district, run_id)
    @ids_and_numbers_without_district = ids_and_numbers
    @ids_and_numbers_with_district = ids_and_numbers_with_district
    @run_id = run_id
  end


  def parse_enrollment_data(file)
    data_array = []
    rows = parse_excel_file(file, 'Enrollment')
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      next if (index == 0)
      state_id = get_row_value(row, headers, 'school id')
      data_hash = {}
      data_hash[:general_id]       = get_general_id(state_id) rescue nil
      data_hash[:general_id]       = get_general_id_with_dirstict(state_id) if data_hash[:general_id].nil?
      data_hash[:school_year]      = get_row_value(row, headers, 'year')
      data_hash[:subgroup]         = get_row_value(row, headers , 'disaggregated')
      data_hash[:demographic]      = get_row_value(row, headers , 'population')
      data_hash[:subgroup_count]   = get_row_value(row, headers , 'total students')
      data_hash[:students_count]   = get_row_value(row, headers , 'number')
      data_hash[:students_percent] = get_row_value(row, headers , 'percentage')
      data_hash                    = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id]           = run_id
      data_hash[:touched_run_id]   = run_id
      data_array << data_hash
    end
    data_array
  end

  def parse_graduation_data(file)
    data_array = []
    rows = parse_excel_file(file, 'Graduation Rate')
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      next if (index == 0)
      state_id = get_row_value(row, headers, 'school id')
      data_hash = {}
      data_hash[:general_id]                     = get_general_id(state_id) rescue nil
      data_hash[:general_id]                     = get_general_id_with_dirstict(state_id) if data_hash[:general_id].nil?
      data_hash[:school_year]                    = get_row_value(row, headers, 'year')
      data_hash[:subgroup]                       = get_row_value(row, headers, 'disaggregated')
      data_hash[:demographic]                    = get_row_value(row, headers, 'population')
      data_hash[:category]                       = get_row_value(row, headers, 'category')
      data_hash[:adjusted_cohort]                = get_row_value(row, headers, 'adjusted cohort')
      data_hash[:graduate_count]                 = get_row_value(row, headers, 'graduate count')
      data_hash[:rate]                           = get_row_value(row, headers, 'rate')
      data_hash[:district_rate]                  = get_row_value(row, headers, 'district rate')
      data_hash[:statewide_rate]                 = get_row_value(row, headers, 'statewide rate')
      data_hash                                  = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id]                         = run_id
      data_hash[:touched_run_id]                 = run_id
      data_array << data_hash
    end
    data_array
  end

  def parse_assesement_data(file)
    data_array = []
    rows = parse_excel_file(file, 'Assessments')
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      beds_code = get_row_value(row, headers, 'school id')
      next if (index == 0)
      data_hash = {}
      data_hash[:general_id]                       = get_general_id(state_id) rescue nil
      data_hash[:general_id]                       = get_general_id_with_dirstict(state_id) if data_hash[:general_id].nil?
      data_hash[:school_year]                      = get_row_value(row, headers, 'year')
      data_hash[:subgroup]                         = get_row_value(row, headers, 'disaggregated')
      data_hash[:demographic]                      = get_row_value(row, headers, 'population')
      data_hash[:subject]                          = get_row_value(row, headers, 'assessment')
      data_hash[:subgroup]                         = get_row_value(row, headers, 'subgroup_name')
      data_hash[:achievement_level]                = get_row_value(row, headers, 'Achievement Level')
      data_hash[:students_required_test_cnt]       = get_row_value(row, headers, 'number of students required to test')
      data_hash[:students_tested_cnt]              = get_row_value(row, headers, 'total_tested')
      data_hash[:students_tested_pct]              = get_row_value(row, headers, 'percentage of students tested')
      data_hash[:students_achiev_lvl_cnt]          = get_row_value(row, headers, 'number of students at achievement level')
      data_hash[:students_achiev_lvl_pct]          = get_row_value(row, headers, 'percentage of students at achievement level')
      data_hash[:students_achiev_lvl_district_pct] = get_row_value(row, headers, 'district - percentage of students at achievement level')
      data_hash[:students_achiev_lvl_state_pct]    = get_row_value(row, headers, 'statewide - percentage of students at achievement level')
      data_hash  = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id]           = run_id
      data_hash[:touched_run_id]   = run_id
      data_array << data_hash
    end
    data_array
  end

  def parse_finance_data(file)
    data_array = []
    rows = parse_excel_file(file, 'Finance')
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      beds_code = get_row_value(row, headers, 'school id')
      next if (index == 0)
      data_hash = {}
      data_hash[:general_id]                     = get_general_id(state_id) rescue nil
      data_hash[:general_id]                     = get_general_id_with_dirstict(state_id) if data_hash[:general_id].nil?
      data_hash[:school_year]                    = get_row_value(row, headers, 'year')
      data_hash[:type]                           = get_row_value(row, headers, 'type')
      data_hash[:category]                       = get_row_value(row, headers, 'category')
      data_hash[:level]                          = get_row_value(row, headers, 'level')
      data_hash[:amount]                         = get_row_value(row, headers, 'amount')
      data_hash[:district_amount]                = get_row_value(row, headers, 'district amount')
      data_hash[:statewide_amount]               = get_row_value(row, headers, 'statewide amount')
      data_hash                                  = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id]                         = run_id
      data_hash[:touched_run_id]                 = run_id
      data_array << data_hash
    end
    data_array
  end

  def parse_perfomance_indicator(file)
    data_array = []
    rows = parse_excel_file(file, 'performance indicator')
    headers = rows.first.map{ |e| e.downcase }
    rows.each_with_index do |row,index|
      beds_code = get_row_value(row, headers, 'school id')
      next if (index == 0)
      data_hash = {}
      data_hash[:general_id]                     = get_general_id(state_id) rescue nil
      data_hash[:general_id]                     = get_general_id_with_dirstict(state_id) if data_hash[:general_id].nil?
      data_hash[:school_year]                    = get_row_value(row, headers, 'year')
      data_hash[:school_level]                   = get_row_value(row, headers, 'school level')
      data_hash[:performance]                    = get_row_value(row, headers, 'performance')
      data_hash[:indicator]                      = get_row_value(row, headers, 'indicator')
      data_hash                                  = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id]                         = run_id
      data_hash[:touched_run_id]                 = run_id
      data_array << data_hash
    end
    data_array
  end

  private

  attr_reader :ids_and_numbers_without_district, :ids_and_numbers_with_district, :run_id

  def get_row_value(row, headers ,key)
    value_index = headers.index(headers.select{ |e| e.include? key }.first)
    row[value_index] unless value_index.nil?
  end

  def get_general_id(key)
    required_array = ids_and_numbers_without_district.select{ |e| e.last == key }.first
    required_array.first unless required_array.nil?
  end

  def get_general_id_with_dirstict(key)
    required_array = ids_and_numbers_with_district.select{ |e| e.last == key }.first
    required_array.first unless required_array.nil?
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def parse_excel_file(file, sheet_name)
    doc = (file.include? 'xlsx') ? Roo::Spreadsheet.open(file) : Roo::Excel.new(file)
    doc.sheet(sheet_name)
  end

end
