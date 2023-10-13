# frozen_string_literal" => true
require 'roo'
class Parser < Hamster::Parser

  def get_xlsx_link(response)
    json_response = json_parse(response)
    config_string = json_response['exploration']["sections"][0]["visualContainers"][8]["config"]
    json_string = json_parse(config_string)
    url_key = json_string.extend(Hashie::Extensions::DeepFind)
    xlsx_link = url_key.deep_find("url")
  end

  def get_data(path, run_id)
    sheet = xlsx_convertion(path)
    data_array = []
    sheet[1..].each do |row|
      data_hash = {}
      data_hash[:unit_name]       = search_value(sheet[0], row, "Unit Name")
      data_hash[:department]      = search_value(sheet[0], row, "Department")
      data_hash[:last_name]       = search_value(sheet[0], row, "Last Name")
      data_hash[:first_initial]   = search_value(sheet[0], row, "First Initial")
      data_hash[:job_title]       = search_value(sheet[0], row, "Job Title")
      data_hash[:contract]        = search_value(sheet[0], row, "Contract")
      data_hash[:appointment_type]     = search_value(sheet[0], row, "Appointment Type")
      data_hash[:full_time_equivalent] = search_value(sheet[0], row, "FTE")
      data_hash[:annual_salary]        = search_value(sheet[0], row, "Annual Salary")
      data_hash[:extract_date]         = search_value(sheet[0], row, "Extract Date").to_date
      data_hash                        = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash]             = create_md5_hash(data_hash)
      data_hash[:run_id]               = run_id
      data_hash[:touched_run_id]       = run_id
      data_array << data_hash
    end
    data_array
  end

  private

  def json_parse(response)
    JSON.parse(response)
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) || (value.to_s.squish == "") || (value.to_s.squish == " ") ? nil : value.to_s.squish}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def xlsx_convertion(path)
    xsl = Roo::Spreadsheet.open(path)
    xsl.as_json
  end

  def search_value(headers_row, values_row, key)
    index = headers_row.find_index(key)
    values_row[index] rescue nil
  end
end
