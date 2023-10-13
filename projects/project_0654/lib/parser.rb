class Parser < Hamster::Parser

  def json_response(response)
    JSON.parse(response.force_encoding('utf-8'))
  end

  def get_request_id(data)
    data["requestorGuid"]
  end

  def get_summary_data(response, pdf_content, pdf, s3, run_id)
    json_response_data = json_response(response)
    data_hash = {}
    data_hash[:court_id]                 = 104
    data_hash[:case_id]                  = json_response_data["caseNumber"]
    return [nil, nil, nil] if data_hash[:case_id] == nil
    data_hash_case_pdfs_on_aws           = get_case_pdfs_on_aws(data_hash, pdf_content, pdf, s3, run_id, "info")
    data_hash[:case_name]                = json_response_data["caseStyle"]
    data_hash[:case_name]                = nil if data_hash[:case_name] == ""
    data_hash[:case_filed_date]          = json_response_data["caseFiledOn"].to_date rescue nil
    data_hash[:case_type]                = json_response_data["caseTypeDescription"]
    data_hash[:case_description]         = nil
    data_hash[:disposition_or_status]    = nil
    data_hash[:status_as_of_date]        = json_response_data["caseStatus"]
    data_hash[:judge_name]               = json_response_data["judgeReassigment"].first["judgeAssigned"] rescue nil
    data_hash[:judge_name]               = nil if data_hash[:judge_name] == "" 
    data_hash[:md5_hash]                 = create_md5_hash(data_hash)
    data_hash[:run_id]                   = run_id
    data_hash[:touched_run_id]           = run_id
    data_hash_case_relations_info_pdf    = get_case_relations_info_pdf(data_hash[:md5_hash], data_hash_case_pdfs_on_aws[:md5_hash], run_id)
    [data_hash, data_hash_case_pdfs_on_aws, data_hash_case_relations_info_pdf]
  end

  def get_party_data(parties_response, case_id, run_id)
    json_response_data = json_response(parties_response)
    hash_array = []
    return hash_array if json_response_data.to_s.include? "There is no parties in this case"
    json_response_data.each do |data_row|
      data_hash = get_is_lawyer_0_data(data_row, case_id, run_id)
      hash_array << data_hash
      next if data_row["attorneyName"] =="" && data_row["attorneyAddress"] ==""
      data_hash = get_is_lawyer_1_data(data_row, case_id, run_id)
      hash_array << data_hash
    end
    hash_array
  end

  def get_case_activities(event_response, activity_pdfs, s3, run_id, path)
    json_response_data = json_response(event_response)
    hash_array = []
    array_activity_pdfs_on_aws = []
    hash_array_relations_activity_pdf = []
    return [nil, nil] if json_response_data["data"] == nil
    json_response_data["data"].each do |data|
      data_hash = {}
      file_name = Digest::MD5.hexdigest data.to_s
      data_hash[:court_id]                 = 104
      data_hash[:case_id]                  = data["caseNumber"]
      unless activity_pdfs.nil?
        file = activity_pdfs.select{|e| e.gsub('.gz','') == file_name}
        unless file.empty?
          pdf_content = get_content(path, file.first)
          hash_activity_pdfs_on_aws = get_case_pdfs_on_aws(data_hash, pdf_content, file.first, s3, run_id, "activity")
        end
      end
      data_hash[:activity_date]            = Date.strptime(data["eventDate"],"%m/%d/%Y")
      data_hash[:activity_decs]            = data["eventDescription"]
      data_hash[:activity_type]            = nil
      data_hash[:md5_hash]                 = create_md5_hash(data_hash)
      data_hash[:activity_pdf]             = (hash_activity_pdfs_on_aws.nil?) ? nil : hash_activity_pdfs_on_aws[:aws_link]
      data_hash[:run_id]                   = run_id
      data_hash[:touched_run_id]           = run_id
      hash_array << data_hash
      unless hash_activity_pdfs_on_aws.nil?
        hash_array_relations_activity_pdf << case_relations_activity_pdf(data_hash[:md5_hash], hash_activity_pdfs_on_aws[:md5_hash], run_id)
        array_activity_pdfs_on_aws << hash_activity_pdfs_on_aws
      end
    end
    [hash_array, hash_array_relations_activity_pdf, array_activity_pdfs_on_aws]
  end

  private

  def case_relations_activity_pdf(activity_md5_hash, aws_pdf_md5_value, run_id)
    data_hash = {}
    data_hash[:court_id]                  = 104
    data_hash[:case_activities_md5]      = activity_md5_hash
    data_hash[:case_pdf_on_aws_md5]      = aws_pdf_md5_value
    data_hash[:run_id]                   = run_id
    data_hash[:touched_run_id]           = run_id
    data_hash
  end

  def get_is_lawyer_0_data(data_row, case_id, run_id)
    data_hash = {}
    data_hash[:court_id]                 = 104
    data_hash[:case_id]                  = case_id
    data_hash[:is_lawyer]                = 0
    data_hash[:party_name]               = data_row["name"]
    data_hash[:party_type]               = data_row["partyType"]
    data_hash[:law_firm]                 = nil
    address_city_state_zip               = get_address_details(data_row, "partyAddress")
    data_hash[:party_address]            = address_city_state_zip.first
    data_hash[:party_city]               = address_city_state_zip[1]
    data_hash[:party_state]              = address_city_state_zip[2]
    data_hash[:party_zip]                = address_city_state_zip.last
    data_hash[:party_description]        = "#{data_hash[:party_name]} #{data_hash[:party_address]}"
    data_hash[:md5_hash]                 = create_md5_hash(data_hash)
    data_hash[:run_id]                   = run_id
    data_hash[:touched_run_id]           = run_id
    data_hash
  end

  def get_content(path, file_name)
    peon.give(subfolder: path, file: file_name)
  end

  def get_is_lawyer_1_data(data_row, case_id, run_id)
    data_hash = {}
    data_hash[:court_id]                 = 104
    data_hash[:case_id]                  = case_id
    data_hash[:is_lawyer]                = 1
    data_hash[:party_name]               = data_row["attorneyName"]
    data_hash[:party_type]               = data_row["partyType"].to_s + " Attorney"
    data_hash[:law_firm]                 = nil
    address_city_state_zip               = get_address_details(data_row, "attorneyAddress")
    data_hash[:party_address]            = address_city_state_zip.first
    data_hash[:party_city]               = address_city_state_zip[1]
    data_hash[:party_state]              = address_city_state_zip[2]
    data_hash[:party_zip]                = address_city_state_zip.last
    phone_no                             = data_row["attorneyPhone"] rescue nil
    data_hash[:party_description]        = "Telephone: #{phone_no} #{data_hash[:party_address]}"
    data_hash[:md5_hash]                 = create_md5_hash(data_hash)
    data_hash[:run_id]                   = run_id
    data_hash[:touched_run_id]           = run_id
    data_hash
  end

  def get_case_relations_info_pdf(info_md5_hash, pdf_on_aws_md5_hash, run_id)
    data_hash = {}
    data_hash[:court_id]                  = 104
    data_hash[:case_info_md5]             = info_md5_hash
    data_hash[:case_pdf_on_aws_md5]       = pdf_on_aws_md5_hash
    data_hash[:run_id]                    = run_id
    data_hash[:touched_run_id]            = run_id
    data_hash
  end

  def get_case_pdfs_on_aws(data, pdf_content, pdf, s3, run_id ,type)
    data_hash = {}
    data_hash[:court_id]                 = data[:court_id]
    data_hash[:case_id]                  = data[:case_id]
    data_hash[:source_type]              = type
    data_hash[:aws_link]                 = "us_courts/#{data_hash[:court_id].to_s}/#{data_hash[:case_id].to_s}/#{pdf.split("_pdf").first}.pdf"
    data_hash[:aws_link]                 = upload_file_to_aws(s3, data_hash, pdf_content)
    data_hash[:source_link]              = "https://hover.hillsclerk.com/CaseReport/CreateReport"
    data_hash[:aws_html_link]            = nil
    data_hash[:md5_hash]                 = create_md5_hash(data_hash)
    data_hash[:run_id]                   = run_id
    data_hash[:touched_run_id]           = run_id
    data_hash
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s == " " || value == 'null' ? nil : value }
  end

  def upload_file_to_aws(s3, aws_data, pdf_content)
    aws_url = "https://court-cases-activities.s3.amazonaws.com/"
    return aws_url + aws_data[:aws_link] unless s3.find_files_in_s3(aws_data[:aws_link]).empty?
    key = aws_data[:aws_link]
    s3.put_file(pdf_content, key, metadata={})
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def get_address_details(data_row, address_type)
    party_address              = data_row[address_type].gsub("<br/>"," ") rescue nil
    party_address              = nil if party_address == ""
    party_city                 = data_row[address_type].split("<br/>").last.split(",").first rescue nil

    if (data_row[address_type].include? ",") == false
      party_state, party_zip, party_city = nil, nil, nil
    end

    party_state                = address_split(data_row, address_type).first rescue nil
    party_zip                  = address_split(data_row, address_type).last rescue nil

    if (data_row[address_type].include? ",") == true && (data_row[address_type].split(",").last.include? "<br/>") == true
      party_state              = address_split(data_row, address_type).last.split("<br/>").first
      party_zip                = nil
      party_city               = data_row[address_type].split(",").last.split("<br/>").last
    end

    party_zip = zip_val(party_zip)
    party_city = city_val(party_city)

    [party_address, party_city, party_state, party_zip]
  end

  def address_split(data_row, address_type)
    data_row[address_type].split(",").last.squish.split(" ")
  end

  def zip_val(party_zip)
    (party_zip != nil && party_zip.scan(/[0-9]/).empty? == true) ? nil : party_zip
  end

  def city_val(party_city)
    (party_city != nil && party_city.scan(/[A-Za-z]/).empty? == true) ? nil : party_city
  end
end
