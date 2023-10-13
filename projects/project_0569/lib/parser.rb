require_relative '../lib/scraper'
require 'roo'

class Parser < Hamster::Parser
  
  def nokogiri_response(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def get_links(response)
    response.css("ul li a").select{|a| a['href'].include? "xlsx"}.map{|a| a['href']}.uniq
  end


  def get_data(path, sheet_number, year, run_id )
    xlsx = Roo::Spreadsheet.open(path) rescue nil
    return [] if xlsx.nil?
    xlsx.default_sheet = xlsx.sheets[sheet_number]
    data_array = []
    if sheet_number == 1
      data_array = get_data_hr(xlsx, year, run_id)
    else
      data_array = get_data_earnings(xlsx, year, run_id)
    end
    data_array
  end

  private

  def get_data_hr(xlsx, year, run_id)
    data_array = []
    xlsx.each_with_index do |row ,index|
      next if index == 0
      data_hash = {}
      data_hash[:temporary_id]            = row[0]
      data_hash[:record_number]           = row[1]
      data_hash[:employee_name]           = row[2]
      data_hash[:employee_first_name], data_hash[:employee_middle_name], data_hash[:employee_last_name] = name_split(row[2]) 
      data_hash[:agency_number]           = row[3]
      data_hash[:agency_name]             = row[4]
      data_hash[:department_number]       = row[5]
      data_hash[:department_name]         = row[6]
      data_hash[:branch_code]             = row[7]
      data_hash[:branch_name]             = row[8]
      data_hash[:job_code]                = row[9]
      data_hash[:job_title]               = row[10]
      data_hash[:location_number]         = row[11]
      data_hash[:location_name]           = row[12]
      if row[13].is_a? Integer || row[13].match(/\d/)
        data_hash[:location_postal_code]  = row[13]
        data_hash[:location_county_name]  = nil
      else
        data_hash[:location_postal_code]  = nil
        data_hash[:location_county_name]  = row[13]
      end
      data_hash[:reg_temp_code]           = row[14]
      data_hash[:reg_temp_desc]           = row[15]
      data_hash[:classified_code]         = row[16]
      data_hash[:classified_desc]         = row[17]
      data_hash[:original_hire_date]      = row[18]
      data_hash[:last_hire_date]          = row[19]
      data_hash[:job_entry_date]          = row[20]
      data_hash[:full_part_time_code]     = row[21]
      data_hash[:full_part_time_desc]     = row[22]
      data_hash[:salary_plan_grid]        = row[23]
      data_hash[:salary_grade_range]      = row[24]
      data_hash[:max_salary_step]         = row[25]
      data_hash[:compensation_rate]       = row[26]
      data_hash[:comp_frequency_code]     = row[27]
      data_hash[:comp_frequency_desc]     = row[28]
      data_hash[:position_fte]            = row[29]
      data_hash[:bargaining_unit_number]  = row[30]
      data_hash[:bargaining_unit_name]    = row[31]
      data_hash[:active_on_june_30]       = row[32]
      data_hash[:year]                    = year
      data_hash[:run_id]                  = run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array
  end

  def get_data_earnings(xlsx, year, run_id)
    data_array = []
    xlsx.each_with_index do |row ,index|
      next if index == 0
      data_hash = {}
      data_hash[:temporary_id]   = row[0]
      data_hash[:regular_wages]  = row[1]
      data_hash[:overtime_wages] = row[2]
      data_hash[:other_wages]    = row[3]
      data_hash[:total_wages]    = row[4]
      data_hash[:year]           = year
      data_hash[:run_id]         = run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == '-') ? nil : value.to_s.squish}
  end

  def name_split(name)
    last_name, first_name, middle_name = nil
    return [first_name, middle_name, last_name] if name == nil or name == ','
    last_name, first_name = (name.split(",").count > 1) ? name.split(",") : name.split(" ")
    if first_name.split(" ").count == 2 
      first_name, middle_name = first_name.split(" ")
    else last_name.split(" ").count == 2 
      last_name, middle_name = last_name.split(" ")
    end
    [first_name.strip, middle_name, last_name]
  end
  
end
