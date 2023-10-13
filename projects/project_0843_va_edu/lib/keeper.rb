# frozen_string_literal: true


require_relative '../models/us_districts'
require_relative '../models/us_schools'
require_relative '../models/va_runs'
require_relative '../models/va_general_info'
require_relative '../models/va_enrollment'
require_relative '../models/va_discipline'
require_relative '../models/va_finances_receipts'
require_relative '../models/va_finances_expenditures'
require_relative '../models/va_finances_salaries'

class Keeper
   
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(VaRuns)
    @run_id = @run_object.run_id
  end

  def store_general_info
    va_districts = UsDistricts.where(state: 'VA').all
    va_districts.each do |us_district|
      hash = {
        is_district: 1,
        district_id: nil,
        number: us_district[:number],
        name: us_district[:name],
        type: us_district[:type],
        low_grade: nil,
        high_grade: nil,
        charter: nil,
        magnet: nil,
        title_1_school: nil,
        title_1_school_wide: nil,
        nces_id: us_district[:nces_id],
        phone: us_district[:phone],
        county: us_district[:county],
        address: us_district[:address],
        city: us_district[:city],
        state: us_district[:state],
        state: us_district[:state],
        zip: us_district[:zip],
        zip_4: nil
      }
      hash[:md5_hash] = get_md5_hash(hash, general_info_keys)
      hash[:touched_run_id] = @run_id
      hash[:run_id] = @run_id
      hash[:data_source_url] = 'DB01.us_schools_raw.us_districts'
      VaGeneralInfo.insert(hash)
    end
    va_schools = UsSchools.where(state: 'VA').all
    va_schools.each do |us_school|
      
      district = UsDistricts.find_by(number: us_school[:district_number])
      if district.nil?
        raise "db01.us_schools_raw.us_districts doesn't include number #{us_school[:district_number]}"
      end
      hash = {
        is_district: 0,
        district_id: district[:id],
        number: us_school[:number],
        name: us_school[:name],
        type: us_school[:type],
        low_grade: us_school[:low_grade],
        high_grade: us_school[:high_grade],
        charter: us_school[:charter],
        magnet: us_school[:magnet],
        title_1_school: us_school[:title_1_school],
        title_1_school_wide: us_school[:title_1_school_wide],
        nces_id: us_school[:nces_id],
        phone: us_school[:phone],
        county: us_school[:county],
        address: us_school[:address],
        city: us_school[:city],
        state: us_school[:state],
        zip: us_school[:zip],
        zip_4: us_school[:zip_4]
      }
      hash[:md5_hash] = get_md5_hash(hash, general_info_keys)
      hash[:touched_run_id] = @run_id
      hash[:run_id] = @run_id
      hash[:data_source_url] = 'DB01.us_schools_raw.us_schools'
      VaGeneralInfo.insert(hash)
    end

  end
  
  def store_enrollment(raw_data)
    header_idx = {}
    raw_data[0].each_with_index do |v, index|
      header_idx[v] = index
    end
    
    raw_data[1..].each do |row|
      hash_data = {}
      
      hash_data[:school_year] = row[header_idx['school_year']].strip if header_idx['school_year']
      hash_data[:subgroup] = row[header_idx['subgroup']].strip if header_idx['subgroup']
      hash_data[:demographic] = row[header_idx['demographic']].strip if header_idx['demographic']
      hash_data[:full_time_count] = row[header_idx['full_time_count']].strip if header_idx['full_time_count']
      hash_data[:part_time_count] = row[header_idx['part_time_count']].strip if header_idx['part_time_count']
      hash_data[:total_count] = row[header_idx['total_count']].strip if header_idx['total_count']
      hash_data[:data_source_url] = 'https://p1pe.doe.virginia.gov/apex/f?p=180:1:::::p_session_id,p_application_name:-7032715505308437042,fallmembership'
    
      if row[header_idx['level']] =~ /Division/i
        padded_number = row[header_idx['division_number']].rjust(3, "0")
        general_info = VaGeneralInfo.find_by(is_district: 1, number: padded_number)
      elsif row[header_idx['level']] =~ /School/i
        padded_district_number = row[header_idx['division_number']].rjust(3, "0")
        padded_school_number = padded_district_number + row[header_idx['school_number']].rjust(4, "0")
        general_info = VaGeneralInfo.find_by(is_district: 0, number: padded_school_number)
      end

      hash_data.each do |key, value|
        hash_data[key] = nil if value == ""
      end

      if general_info
        hash_data[:general_id] = general_info[:id]
      else
        
        if row[header_idx['level']] =~ /Division/i
          general_info_id = store_district_to_general_info(padded_number, row, header_idx)
        elsif row[header_idx['level']] =~ /School/i
          general_info_id = store_school_to_general_info(padded_district_number, padded_school_number, row, header_idx)
        end
        hash_data[:general_id] = general_info_id
        # raise "Error: cannot find general info. Division Number: #{row[header_idx['division_number']]}, Division Name: #{row[header_idx['division_name']]}, School Number: #{row[header_idx['school_number']]}, School Name: #{row[header_idx['school_name']]}"
      end      
      hash_data[:md5_hash] = get_md5_hash(hash_data, enrollment_keys)
      hash_data[:touched_run_id] = @run_id
      hash_data[:run_id] = @run_id
      Hamster.logger.debug hash_data
      dig = VaEnrollment.find_by(md5_hash: hash_data[:md5_hash])
      if dig
        dig.update(hash_data)
      else
        VaEnrollment.insert(hash_data)
      end
    end
    
  end

  def store_district_to_general_info(padded_number, row, header_idx)
    hash = {
      is_district: 1,
      district_id: nil,
      number: padded_number,
      name: row[header_idx['division_name']]
    }
    hash[:md5_hash] = get_md5_hash(hash, general_info_keys)
    hash[:touched_run_id] = @run_id
    hash[:run_id] = @run_id
    hash[:data_source_url] = 'https://p1pe.doe.virginia.gov/apex/f?p=180:1:::::p_session_id,p_application_name:-7032715505308437042,fallmembership'
    general_info = VaGeneralInfo.new(hash)
    general_info.save
    general_info.id
  end

  def store_district_to_general_info_v2(padded_number, div_name)
    hash = {
      is_district: 1,
      district_id: nil,
      number: padded_number,
      name: div_name
    }
    hash[:md5_hash] = get_md5_hash(hash, general_info_keys)
    hash[:touched_run_id] = @run_id
    hash[:run_id] = @run_id
    hash[:data_source_url] = 'https://p1pe.doe.virginia.gov/apex/f?p=180:1:::::p_session_id,p_application_name:-7032715505308437042,fallmembership'
    general_info = VaGeneralInfo.new(hash)
    general_info.save
    general_info.id
  end
  
  def store_school_to_general_info(padded_district_number, padded_school_number, row, header_idx)
    district = VaGeneralInfo.find_by(is_district: 1, number: padded_district_number)
    
    unless district
      district_id = store_district_to_general_info(padded_district_number, row, header_idx)
    else
      district_id = district.id
    end
    
    hash = {
      is_district: 0,
      district_id: district_id,
      number: padded_school_number,
      name: row[header_idx['school_name']]
    }
    hash[:md5_hash] = get_md5_hash(hash, general_info_keys)
    hash[:touched_run_id] = @run_id
    hash[:run_id] = @run_id
    hash[:data_source_url] = 'https://p1pe.doe.virginia.gov/apex/f?p=180:1:::::p_session_id,p_application_name:-7032715505308437042,fallmembership'
    general_info = VaGeneralInfo.new(hash)
    
    general_info.save
    general_info.id
  end

  def store_school_to_general_info_v2(padded_district_number, padded_school_number, div_name, sch_name)
    district = VaGeneralInfo.find_by(is_district: 1, number: padded_district_number)
    
    unless district
      district_id = store_district_to_general_info_v2(padded_district_number, div_name)
    else
      district_id = district.id
    end
    
    hash = {
      is_district: 0,
      district_id: district_id,
      number: padded_school_number,
      name: sch_name
    }
    hash[:md5_hash] = get_md5_hash(hash, general_info_keys)
    hash[:touched_run_id] = @run_id
    hash[:run_id] = @run_id
    hash[:data_source_url] = 'https://p1pe.doe.virginia.gov/apex/f?p=180:1:::::p_session_id,p_application_name:-7032715505308437042,fallmembership'
    general_info = VaGeneralInfo.new(hash)
    
    general_info.save
    general_info.id
  end

  def store_discipline_state(raw_data)
    headers = {}
    if raw_data[0][0].include?('School Year')
      raw_data[0].each_with_index do |v, i|
        headers[v] = i
      end
    else
      raise "Error: no headers information in xlsx data"
    end

    raw_data[1..].each do |row|
      discipline_data = {
        general_id: nil,
        school_year: row[headers['School Year']],
        subgroup: row[headers['Subgroup']],
        grade: row[headers['Grade']],
        count: row[headers['Number of Chronically Absent Students']],
        percent: row[headers['Percent Chronically Absent']],
        discipline: 'Chronically Absent Students',
        data_source_url: 'https://www.doe.virginia.gov/data-policy-funding/data-reports/data-collection/special-education',
        deleted: false
      }
      if discipline_data[:subgroup] =~ /All Students/i
        discipline_data[:discipline] = 'Truancy'
      end
      discipline_data[:touched_run_id] = @run_id
      discipline_data[:run_id] = @run_id
      discipline_data[:md5_hash] = get_md5_hash(discipline_data, discipline_keys)
      VaDiscipline.insert(discipline_data)
    end

  end

  def store_discipline_division(raw_data)
    headers = {}
    if raw_data[0][0].include?('School Year')
      raw_data[0].each_with_index do |v, i|
        headers[v] = i
      end
    else
      raise "Error: no headers information in xlsx data"
    end
    raw_data[1..].each do |row|
      discipline_data = {
        school_year: row[headers['School Year']],
        subgroup: row[headers['Subgroup']],
        grade: row[headers['Grade']],
        count: row[headers['Number of Chronically Absent Students']],
        percent: row[headers['Percent Chronically Absent']],
        discipline: 'Chronically Absent Students',
        data_source_url: 'https://www.doe.virginia.gov/data-policy-funding/data-reports/data-collection/special-education',
        deleted: false
      }
      
      general_info = VaGeneralInfo.find_by(is_district: 1, number: row[headers['Div Num']].to_s.rjust(3, '0'))
      if general_info
        discipline_data[:general_id] = general_info.id
      else
        district_num_code = row[headers['Div Num']].to_s.rjust(3, '0')
        discipline_data[:general_id] = store_district_to_general_info_v2(district_num_code, row[headers['Div Name']])
        Hamster.logger.debug "Warning: there is no division number in va_general_info, division number: #{row[headers['Div Num']].to_s.rjust(3, '0')}"
      end
      if discipline_data[:subgroup] =~ /All Students/i
        discipline_data[:discipline] = 'Truancy'
      end
      discipline_data[:touched_run_id] = @run_id
      discipline_data[:run_id] = @run_id
      discipline_data[:md5_hash] = get_md5_hash(discipline_data, discipline_keys)
      VaDiscipline.insert(discipline_data)
      break
    end
  end

  def store_discipline_school_from_stream(row, headers)
    discipline_data = {
      school_year: row[headers['School Year']],
      subgroup: row[headers['Subgroup']],
      grade: row[headers['Grade']],
      count: row[headers['Number of Chronically Absent Students']],
      percent: row[headers['Percent Chronically Absent']],
      discipline: 'Chronically Absent Students',
      data_source_url: 'https://www.doe.virginia.gov/data-policy-funding/data-reports/data-collection/special-education',
      deleted: false
    }
    district_num_code = row[headers['Div Num']].to_s.rjust(3, '0')
    school_num_code = district_num_code + row[headers['Sch Num']].to_s.rjust(4, '0')
    general_info = VaGeneralInfo.find_by(is_district: 0, number: school_num_code)
    if general_info
      discipline_data[:general_id] = general_info.id
    else
      discipline_data[:general_id] = store_school_to_general_info_v2(district_num_code, school_num_code, row[headers['Div Name']], row[headers['Sch Name']])
      Hamster.logger.debug "Warning: there is no division number in va_general_info, division number: #{row[headers['Div Num']].to_s.rjust(3, '0')}"
    end
    if discipline_data[:subgroup] =~ /All Students/i
      discipline_data[:discipline] = 'Truancy'
    end
    discipline_data[:touched_run_id] = @run_id
    discipline_data[:run_id] = @run_id
    discipline_data[:md5_hash] = get_md5_hash(discipline_data, discipline_keys)
    Hamster.logger.debug discipline_data[:md5_hash]
    VaDiscipline.insert(discipline_data)
  end

  def store_finances_receipts(hash_data)
    data = hash_data.except(:div_num, :div_name)
    padded_div_num = hash_data[:div_num].to_s.rjust(3, "0")
    general_info = VaGeneralInfo.find_by(is_district: 1, number: padded_div_num)
    if general_info.nil?
      data[:general_id] = store_district_to_general_info_v2(padded_div_num, hash_data[:div_name])
    else
      data[:general_id] = general_info.id
    end
    data[:data_source_url] = 'https://www.doe.virginia.gov/data-policy-funding/data-reports/statistics-reports/superintendent-s-annual-report'
    data[:md5_hash] = get_md5_hash(data, finances_receipts_keys)
    data[:touched_run_id] = @run_id
    data[:run_id] = @run_id
    VaFinancesReceipts.insert(data)
  end

  def store_finances_expenditures(row, year)

    padded_div_num = row[0].to_s.rjust(3, "0")

    general_info = VaGeneralInfo.find_by(is_district: 1, number: padded_div_num)
    
    data = {
      fiscal_year: year,
      data_source_url: 'https://www.doe.virginia.gov/data-policy-funding/data-reports/statistics-reports/superintendent-s-annual-report',
      touched_run_id: @run_id,
      run_id: @run_id
    }
    if general_info.nil?
      if row[1].strip.empty?
        raise "Error, failed to storing general info because of empty division number."
      end
      data[:general_id] = store_district_to_general_info_v2(padded_div_num, row[1])
    else
      data[:general_id] = general_info.id
    end

    # Make data
    data[:source] = 'End-of-Year ADM for Determining Cost Per Pupil'
    data[:amount] = row[2]
    data[:per_pupil] = nil
    data[:md5_hash] = get_md5_hash(data, finances_expenditures_keys)
    VaFinancesExpenditures.insert(data)

    data[:source] = 'Local'
    data[:amount] = row[3]
    data[:per_pupil] = row[4]
    data[:md5_hash] = get_md5_hash(data, finances_expenditures_keys)
    VaFinancesExpenditures.insert(data)
    
    data[:source] = 'State'
    data[:amount] = row[5]
    data[:per_pupil] = row[6]
    data[:md5_hash] = get_md5_hash(data, finances_expenditures_keys)
    VaFinancesExpenditures.insert(data)

    data[:source] = 'State Retail Sales And Use Tax'
    data[:amount] = row[7]
    data[:per_pupil] = row[8]
    data[:md5_hash] = get_md5_hash(data, finances_expenditures_keys)
    VaFinancesExpenditures.insert(data)

    data[:source] = 'Federal'
    data[:amount] = row[9]
    data[:per_pupil] = row[10]
    data[:md5_hash] = get_md5_hash(data, finances_expenditures_keys)
    VaFinancesExpenditures.insert(data)

    data[:source] = 'Total'
    data[:amount] = row[11]
    data[:per_pupil] = row[12]
    data[:md5_hash] = get_md5_hash(data, finances_expenditures_keys)
    VaFinancesExpenditures.insert(data)
  end

  def store_finances_salaries(row, year)
    padded_div_num = row[0].to_s.rjust(3, "0")
    general_info = VaGeneralInfo.find_by(is_district: 1, number: padded_div_num)
    
    data = {
      fiscal_year: year,
      data_source_url: 'https://www.doe.virginia.gov/data-policy-funding/data-reports/statistics-reports/superintendent-s-annual-report',
      touched_run_id: @run_id,
      run_id: @run_id
    }
    if general_info.nil?
      if hash_data[1].strip.empty?
        raise "Error, failed to storing general info because of empty division number."
      end
      data[:general_id] = store_district_to_general_info_v2(padded_div_num, hash_data[1])
    else
      data[:general_id] = general_info.id
    end

    # --- Principals ---
    data[:position] = 'Principals'
    data[:type] = 'Elementary Positions'
    data[:positions_count] = row[2]
    data[:avg_salary] = row[3]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    data[:position] = 'Principals'
    data[:type] = 'Secondary Positions'
    data[:positions_count] = row[4]
    data[:avg_salary] = row[5]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    data[:position] = 'Principals'
    data[:type] = 'Total Positions'
    data[:positions_count] = row[6]
    data[:avg_salary] = row[7]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    # --- Assistant Principals ---
    data[:position] = 'Assistant Principals'
    data[:type] = 'Elementary Positions'
    data[:positions_count] = row[8]
    data[:avg_salary] = row[9]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    data[:position] = 'Assistant Principals'
    data[:type] = 'Secondary Positions'
    data[:positions_count] = row[10]
    data[:avg_salary] = row[11]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    data[:position] = 'Assistant Principals'
    data[:type] = 'Total Positions'
    data[:positions_count] = row[12]
    data[:avg_salary] = row[13]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    # --- Teaching Positions ---
    data[:position] = 'Teaching Positions'
    data[:type] = 'Elementary Positions'
    data[:positions_count] = row[14]
    data[:avg_salary] = row[15]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    data[:position] = 'Teaching Positions'
    data[:type] = 'Secondary Positions'
    data[:positions_count] = row[16]
    data[:avg_salary] = row[17]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    data[:position] = 'Teaching Positions'
    data[:type] = 'Total Positions'
    data[:positions_count] = row[18]
    data[:avg_salary] = row[19]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    # --- All Instructional Positions ---
    data[:position] = nil
    data[:type] = 'All Instructional Positions'
    data[:positions_count] = row[20]
    data[:avg_salary] = row[21]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    # --- Teacher Aides Positions ---
    data[:position] = nil
    data[:type] = 'Teacher Aides Positions'
    data[:positions_count] = row[22]
    data[:avg_salary] = row[23]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

    # --- District Wide Instructional Positions ---
    data[:position] = nil
    data[:type] = 'District Wide Instructional Positions'
    data[:positions_count] = row[24]
    data[:avg_salary] = row[25]
    data[:md5_hash] = get_md5_hash(data, finances_salaries_keys)
    VaFinancesSalaries.insert(data)

  end

  def get_md5_hash(hash_data, params)
    data_str = hash_data.slice(*params).values.join('')
    md5_hash = Digest::MD5.hexdigest(data_str)
  end

  def general_info_keys
    [:is_district, :district_id, :number, :name, :type, :nces_id]
  end
  
  def enrollment_keys
    [:general_id, :school_year, :subgroup, :demographic]
  end

  def discipline_keys
    [:general_id, :school_year, :discipline, :subgroup, :grade, :deleted]
  end

  def finances_receipts_keys
    [:general_id, :fiscal_year]
  end

  def finances_expenditures_keys
    [:general_id, :fiscal_year, :source]
  end

  def finances_salaries_keys
    [:general_id, :fiscal_year, :position, :type]
  end

  def finish
    @run_object.finish
  end

  def mark_delete
    models = [VaGeneralInfo]
    models.each do |model|
      model.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    end
  end
  
end

