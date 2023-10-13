# frozen_string_literal: true
require_relative '../lib/manager'
require 'roo'
require 'roo-xls'
require 'spreadsheet'

class Parser < Hamster::Parser

  BASE_URL = "https://www.nh.gov/transparentnh/search/"
  HEADER_MAPPING = {
    "EMPLOYEE LAST NAME" => "employee_last_name",
    "EMPLOYEE FIRST NAME" => "employee_first_name",
    "MI" => "employee_middle_initial",
    "TITLE" => "title",
    "PAY CATEGORY" => "pay_category",
    "AGENCY" => "agency",
    "ANNUAL SALARY" => "annual_salary",
    "INTERNAL EMPL ID" => "internal_employee_id",
    "ACTIVE/INACTIVE" => "status"
  }.freeze
  HEADER_MAPPING2 = {
    "LAST NAME" => "employee_last_name",
    "FIRST NAME" => "employee_first_name",
    "MIDDLE INITIAL" => "employee_middle_initial",
    "TITLE" => "title",
    "PAY TYPE" => "pay_category",
    "AGENCY" => "agency",
    "PAY" => "annual_salary",
    "ACTIVE/INACTIVE" => "status"
  }.freeze


  def initialize
    super
    # code to initialize object
  end

  def get_links(response)
    html = Nokogiri::HTML response
    html.xpath("//div[@id='PageContent']//ul/li/a[contains(text(), 'Download CY')]/@href").map{|e| BASE_URL + e.value}
  end

  def parse_file(path, run_id)
    year = path.split("/").last.gsub(/\.(xlsx|xls)/,"").to_i

    workbook = if path =~ /\.xlsx$/
                 Roo::Excelx.new(path)
               elsif path =~ /\.xls$/
                 Roo::Excel.new(path)
               else
                 raise ArgumentError, "Invalid file format. Only XLSX and XLS files are supported."
               end

    sheet_index = workbook.sheets.count == 1 ? 0 : 1
    sheet = workbook.sheet(sheet_index)

    headers = sheet.row(1).map{|e| e.squish.gsub(" / ","/")}

    if headers[0] == "LAST NAME"
      mapped_headers = headers.map { |header| HEADER_MAPPING2[header] }
    else
      mapped_headers = headers.map { |header| HEADER_MAPPING[header] }
    end

    data = []

    (2..sheet.last_row).each do |row_num|
      row = sheet.row(row_num)
      hash = {}

      mapped_headers.each_with_index do |header, index|
        hash[header] = row[index].to_s
      end

      if row.count == 8
        hash["internal_employee_id"] = ""
      end

      hash["status"] = hash["status"] == "A" ? "Active" : "In Active"
      hash["year"] = year
      hash["data_source_url"] = "https://www.nh.gov/transparentnh/search/documents/#{year}-employee-pay.xlsx"
      hash = mark_empty_as_nil(hash)
      md5_hash = MD5Hash.new(columns: hash.keys)
      md5_hash.generate(hash)
      hash[:md5_hash] = md5_hash.hash
      hash[:run_id] = run_id
      hash[:touched_run_id] = run_id

      data << hash
    end

    data
  end

  def parse_file_old(path, run_id)

    year = path.split("/").last.gsub(/\.(xlsx|xls)/,"").to_i

    if path =~ /\.xlsx$/
      workbook = Roo::Excelx.new(path)
      sheet_index = workbook.sheets.count == 1 ? 0 : 1
      sheet = workbook.sheet(sheet_index)
      sheet_num = 2
      sheet_last_num = sheet.last_row
    elsif path =~ /\.xls$/
      workbook = Spreadsheet.open(path)
      sheet_index = workbook.worksheets.count == 1 ? 0 : 1
      sheet = workbook.worksheet(sheet_index)
      sheet_num = 1
      sheet_last_num = sheet.row_count
    else
      raise ArgumentError, "Invalid file format. Only XLSX and XLS files are supported."
    end

    data = []

    (sheet_num..sheet_last_num).each do |row_num|
      row = sheet.row(row_num)
      hash = {}

      headers.each_with_index do |header, index|
        hash[header] = row[index].to_s
      end

      hash["status"] = hash["status"] == "A" ? "Active" : "In Active"
      hash["year"] = year
      hash["data_source_url"] = "https://www.nh.gov/transparentnh/search/documents/#{year}-employee-pay.xlsx"
      hash = mark_empty_as_nil(hash)
      md5_hash = MD5Hash.new(columns: hash.keys)
      md5_hash.generate(hash)
      hash[:md5_hash] = md5_hash.hash
      hash[:run_id] = run_id
      hash[:touched_run_id] = run_id

      data << hash
    end

    data
  end


  private


  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end

end

