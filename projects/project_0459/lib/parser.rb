# frozen_string_literal: true
class Parser < Hamster::Parser

  def get_records(html)
    data = JSON.parse(html)
    records = data["result"]["items"]
    return [] if records.count == 0
    records
  end

  def prepare_hash(body, json_obj, run_id)
    index_no = body.index('<main')
    body = body[index_no..-1]
    index_no = body.index('</main>')
    return {} if index_no == nil
    body = body[0..index_no+6].force_encoding("utf-8")
    parsed_content = Nokogiri::HTML(body)
    data_hash={}
    data_hash["law_firm_zip"], data_hash["law_firm_city"], data_hash["law_firm_state"] = nil

    parsed_content.css('div.-details dl dt').each_with_index do |key,index|
      key = key.text.gsub(":","").downcase.gsub(" ","_")
      if key == 'address'
        data_hash[key] = parsed_content.css('div.o-content dl dd')[index].text.strip.split("\n").map{|s| s.squish}.join("\n")
      else
        data_hash[key] = parsed_content.css('div.o-content dl dd')[index].text.squish
      end

      if data_hash[key] == 'N/A'
        data_hash[key] = nil
      end
    end

    data_hash["date_of_admission"] = DateTime.strptime(data_hash["date_of_admission"], '%m/%d/%Y').to_date rescue nil
    address = data_hash["address"]

    if address != nil && data_hash["country"] == 'UNITED STATES'
      data_hash["law_firm_city"], data_hash["law_firm_state"], data_hash["law_firm_zip"] = get_address_values(address)
    end

    data_hash["name"]              = json_obj["collectionDisplayName"]
    data_hash["first_name"]        = json_obj["firstName"]
    data_hash["last_name"]         = json_obj["lastName"]
    data_hash["middle_name"]       = json_obj["middleName"]
    data_hash["email"]             = json_obj["email"]
    data_hash["data_source_url"]   = "https://www.padisciplinaryboard.org/for-the-public/find-attorney/attorney-detail/#{data_hash["attorney_id"]}"
    data_hash["phone"]             = data_hash.delete("telephone")
    data_hash["law_firm_address"]  = data_hash.delete("address")
    data_hash["judicial_district"] = data_hash.delete("district")
    data_hash["law_firm_county"]   = data_hash.delete("county")
    data_hash["law_firm_country"]  = data_hash.delete("country")
    data_hash["bar_number"]        = data_hash.delete("attorney_id")
    data_hash["date_admited"]      = data_hash.delete("date_of_admission")
    data_hash = clean_data_hash(data_hash)
    data_hash.update(additional_columns(data_hash, run_id))
    data_hash
  end

  private

  def clean_data_hash(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def additional_columns(data, run_id)
    data_info = {}
    data_info[:md5_hash]          = create_md5_hash(data)
    data_info[:run_id]            = run_id
    data_info[:touched_run_id]    = run_id
    data_info
  end

  def check_zip(value)
    value.split(' ').select{|s| s.scan(/\d+/).count > 0}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end

  def get_address_values(address)
    last_line = address.split("\n").last
    address_split = last_line.split(',').reject{|s| s == ""}
    city = address_split[0]
    if address_split.count > 1
      if check_zip(address_split.last).count > 0
        zip = check_zip(address_split.last).first
       state = address_split.last.gsub(zip, '').strip
      else
        state = address_split.last
      end
    else
      if check_zip(city).count > 0
        zip = check_zip(city).first
        city = city.gsub(zip, '').strip
      end
    end
    [city, state, zip]
  end
end
