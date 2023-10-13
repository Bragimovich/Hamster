# frozen_string_literal: true
class Parser < Hamster::Parser

  def get_agency_name_array(data)
    response = parse_into_json(data)
    response["data"]
  end

  def get_data(data, run_id, inserted_records)
    response = parse_into_json(data)
    data = []
    response["data"].each do |row|
      data_hash={}
      data_hash[:agency] = row["agencyName"]
      data_hash[:first_name] = row["firstName"]
      data_hash[:last_name] = row["lastName"]
      data_hash[:full_name] = data_hash[:last_name].downcase == "null" ? data_hash[:first_name] : "#{data_hash[:first_name]} #{data_hash[:last_name]}"
      data_hash[:job_title] = row["jobTitle"]
      data_hash[:full_time_or_part_time] = row["fullPart"]
      data_hash[:compensation_rate] = row["compRate"].to_f
      data_hash[:compensation_rate_period] = row["compRatePeriod"]
      data_hash[:source_updated_date] = Date.strptime(row["loadDate"], '%m/%d/%y')
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      if inserted_records.include? data_hash[:md5_hash]
        inserted_records.delete data_hash[:md5_hash]
        next
      end
      data_hash.delete(:md5_hash)
      data_hash[:run_id] = run_id
      data << data_hash
    end
    [data, inserted_records]
  end

  private

  def parse_into_json(response)
    JSON.parse(response)
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
