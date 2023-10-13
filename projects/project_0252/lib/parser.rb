# frozen_string_literal: true
require 'roo'
require 'roo-xls'
class Parser < Hamster::Parser

  def process_file(run_id, file, db_md5)
    xlsx = Roo::Spreadsheet.open(file)
    sheet = xlsx.sheet(0)
    headers, update_array, hash_array = [], [],[]
    sheet.each_row_streaming.each_with_index do |row, index|
      if index == 0
        headers = json_parsing(row).map{|e| e["cell_value"].downcase.gsub(" ","_")}
        next
      end
      data = json_parsing(row)
      data_hash = {}
      data.each_with_index do |dat, data_index|
        if headers[data_index].include? 'address'
          data_hash["#{headers[data_index].gsub("_","")}"] = dat["cell_value"]
        elsif headers[data_index].include? 'grade'
          data_hash["grades"] = dat["cell_value"]
        elsif headers[data_index] == 'org_code'
          data_hash["org_id"] = set_org_code(dat["cell_value"])
        elsif headers[data_index] == 'town'
          data_hash["city"] = dat["cell_value"]
        elsif headers[data_index] == 'function'
          data_hash["contact_role"] = dat["cell_value"]
        else
          data_hash["#{headers[data_index]}"] = dat["cell_value"]
        end
      end
      data_hash["zip"] = set_zip_value(data_hash)
      data_hash["org_name"] = set_school_name(data_hash) if file.include? 'school'

      data_hash.delete "function"
      data_hash.delete "town"

      md5 = md5_gen(data_hash)
      if db_md5.include? md5
        update_array << md5
        next
      end
      data_hash["data_source_url"] = "https://profiles.doe.mass.edu/search/search.aspx?leftNavId=11238"
      data_hash["created_by"] = "Aqeel"
      data_hash["run_id"] = run_id
      data_hash["touched_run_id"] = run_id
      data_hash["pl_gather_task_id"] = 168734706
      data_hash["scrape_status"] = "Live"
      data_hash["dataset_name_prefix"] = "massachusetts"
      data_hash["expected_scrape_frequency"] = "Yearly"

      hash_array << data_hash
    end
    [hash_array, update_array]
  end

  private

  def set_zip_value(data_hash)
    data_hash["zip"].size == 4 ? "0#{data_hash["zip"]}" : data_hash["zip"]
  end

  def set_school_name(data_hash)
    (data_hash["org_name"].include? ":") ? data_hash["org_name"].split(":").last.strip : data_hash["org_name"]
  end

  def set_org_code(value)
    total_len = 8
    org_len = value.length
    diff = total_len - org_len
    "#{"0"*diff}#{value}"
  end

  def md5_gen(data_hash)
    md5 = MD5Hash.new(:columns => data_hash.keys)
    md5.generate(data_hash)
  end

  def json_parsing(row)
    JSON.parse(row.to_json)
  end
end
