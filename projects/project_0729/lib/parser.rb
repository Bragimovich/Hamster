# frozen_string_literal: true
require_relative '../lib/headers'
require 'roo'

class Parser < Hamster::Parser
  include Headers
  def parse_page(response)
    Nokogiri::HTML(response)
  end

  def get_html_data(response)
    response.css("a").select{|a| a.text.include? "Download the data"}.map{ |a| a["href"]}
  end

  def excel_data(path, link, run_id)
    payroll_data = []
    employee_salaries = []
    xsl = Roo::Spreadsheet.open(path)
    [1, 2].lazy.each do |sheet_index|
      xsl.default_sheet = xsl.sheets[sheet_index]
      data_lines = xsl.as_json
      data_lines.lazy.each_with_index do |row, index|
        next if index == 0

        if sheet_index == 1
          payroll_data << payroll_data_columns(row, link, run_id, data_lines)
        elsif sheet_index == 2
          employee_salaries << employee_salaries_columns(row, link, run_id)
        end
      end
    end
    [payroll_data, employee_salaries]
  end  

  def employee_salaries_columns(row, link, run_id)
    data_hash = {}
    data_hash = salary_headers
    data_hash.keys.each_with_index do |key, index|
      data_hash[key] = row[index].to_i
    end
    data_hash.merge!(common_columns(data_hash, link, run_id))
    data_hash
  end  

  def payroll_data_columns(row, link, run_id, data_lines)
    index_array = [0,1,8,22,23,24,27,28]
    data_hash = {}
    data_hash = payroll_headers
    data_hash.keys.each_with_index do |key, index|
      counter = index < 1  ? index : index + 1
      counter = index > 11 ? counter + 1 : counter
      value   = (index_array.include? index) ? row[counter].to_i : row[counter].to_s
      data_hash[key] = value
    end
    data_hash.merge!(split_name(row[2]))
    if data_lines[0][13].include?("CODE")
      data_hash[:location_postal_code]  = row[13].to_i
    else   
      data_hash[:location_county_name]  = row[13].to_s
    end 
    data_hash.merge!(common_columns(data_hash, link, run_id))
    data_hash  
  end  

  def split_name(name)
    data_hash = {}
    last_name, first_middle_name = name.to_s.split(',').map(&:strip)
    seperated_name = first_middle_name&.split(' ') || ['', '']
    if seperated_name.size > 1
      middle_name = seperated_name[1]
      first_name  = seperated_name[0]
    else
      first_name, middle_name = [seperated_name[0], nil]
    end
    data_hash[:employee_last_name]       = last_name
    data_hash[:employee_first_name]      = first_name
    data_hash[:employee_middle_initial]  = middle_name
    data_hash
  end

  def common_columns(date_hash, link, run_id)
    {
      md5_hash:              create_md5_hash(date_hash),
      data_source_url:       link,
      run_id:                run_id, 
      touched_run_id:        run_id
    }  
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
