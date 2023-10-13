# frozen_string_literal: true

class Parser < Hamster::Parser
  
  def links_count(response)
    content = JSON.parse(response.body)
    content["resultItems"].count
  end

  def get_links(response)
    ids = []
    content = JSON.parse(response.body)
    content["resultItems"].each do |item|
      ids << item["id"]
    end
    ids
  end

  def file_key(response)
    JSON.parse(response.body)[0]["documentID"]
  end

  def parse_content(file)
    JSON.parse(file)
  end

  def case_info_parser(info_file, lowercourt_file)
    case_info_response = parse_content(info_file)
    lower_court_response = parse_content(lowercourt_file)
    case_id = case_info_response["caseNumber"]
    return [] if case_info_response.empty?
    if (case_id.include? "CA") && (case_info_response["court"] == "Kentucky Court of Appeals")
      court_id = 18 
    elsif (case_id.include? "SC") && (case_info_response["court"] == "Kentucky Supreme Court")
      court_id = 17
    end
    case_name = case_info_response["fullTitle"].squish rescue nil
    case_name = (case_name == "" || case_name.nil?) ? (case_info_response["shortTitle"].squish rescue nil) : (case_info_response["fullTitle"].squish rescue nil)
    lower_case_id = (!lower_court_response.empty?) ? lower_court_response[0]["lowerCourtCaseNumber"] : nil
    case_info_hash  = {
      case_id: case_id,
      court_id: court_id,
      case_name: case_name,
      case_filed_date: case_info_response["filedDate"],
      case_type: case_info_response["caseClassification"].squish,
      disposition_or_status: case_info_response["caseStatus"],
      status_as_of_date: case_info_response["caseStatusDate"],
      lower_case_id: lower_case_id,
      data_source_url: "https://appellatepublic.kycourts.net/case/#{case_info_response["caseID"]}"
    }
    case_info_hash[:md5_hash] = MD5Hash.new(:table=>:info).generate(case_info_hash)
    status_as_of_date = case_info_hash[:disposition_or_status]
    case_info_hash[:disposition_or_status] = case_info_hash[:status_as_of_date]
    case_info_hash[:status_as_of_date] = status_as_of_date
    case_info_hash
  end

  def case_party_parser(file, case_info_hash,run_id)
    data_array = []
    case_party_response = parse_content(file)
    return data_array if case_party_response.empty? 
    case_party_response.each do |data|
      role = data["partyName"]["role"]
      data_hash = {}
      data_array << prepare_party_hash(data , case_info_hash, 0, role, run_id)
      if data["attorneys"]
        data["attorneys"].each do |attorney|
          data_array << prepare_party_hash(attorney, case_info_hash, 1, role, run_id)
        end
      end
    end
    data_array
  end

  def case_additional_info(file, case_info_hash, run_id)
    lower_court_response = parse_content(file)
    return {} if lower_court_response.empty?
    data_array = []
    lower_court_response.each do |data|
      lower_court_hash = {
        case_id: case_info_hash[:case_id],
        court_id: case_info_hash[:court_id],
        lower_court_name: data["lowerCourtName"],
        lower_case_id: data["lowerCourtCaseNumber"],
        data_source_url: case_info_hash[:data_source_url]
      }
      lower_court_hash[:md5_hash] = generate_md_hash(lower_court_hash)
      lower_court_hash[:run_id] = run_id
      lower_court_hash[:touched_run_id] = run_id
      data_array << lower_court_hash
    end
    data_array
  end

  def case_activities_info(case_info_hash, activity, file, run_id, case_pdfs_on_aws_hash)
    case_activity_hash = {
      case_id: case_info_hash[:case_id],
      court_id: case_info_hash[:court_id],
      activity_date: activity["filedDate"],
      activity_type: activity["docketEntryType"],
      activity_desc: activity["docketEntryDescription"],
      file: file,
      data_source_url: case_info_hash[:data_source_url]
    
    }
    case_activity_hash[:md5_hash] = generate_md_hash(case_activity_hash)
    case_activity_hash[:run_id] = run_id
    case_activity_hash[:touched_run_id] = run_id
    if activity["hasDocuments"] == true
      case_relations_activity_pdf = {
        case_activities_md5: case_activity_hash[:md5_hash],
        case_pdf_on_aws_md5: case_pdfs_on_aws_hash[:md5_hash]
      }
    else
      case_relations_activity_pdf = {}
    end
    [case_activity_hash, case_relations_activity_pdf ]
  end

  def case_pdfs_on_aws_parser(case_info_hash, file, aws_link,run_id)
    case_pdfs_on_aws_hash = {
      case_id: case_info_hash[:case_id],
      court_id: case_info_hash[:court_id],
      source_type: "activity",
      aws_link: aws_link,
      source_link: file
    }
    case_pdfs_on_aws_hash[:md5_hash] = generate_md_hash(case_pdfs_on_aws_hash)
    case_pdfs_on_aws_hash[:run_id] = run_id
    case_pdfs_on_aws_hash[:touched_run_id] = run_id
    case_pdfs_on_aws_hash
  end

  private

  def prepare_party_hash(party_hash, case_info_hash, is_lawyer, role, run_id)
    case_party_hash = {}
    if party_hash["address"]
      add = party_hash["address"]
      case_party_hash[:party_address] = [add["line1"],add["line2"],add["line3"],add["line4"]].join(" ").strip
      case_party_hash[:party_city] = add["city"]
      case_party_hash[:party_state] = add["state"]
      case_party_hash[:party_zip] = add["postalCode"]
    else
      case_party_hash[:party_address] =  nil
      case_party_hash[:party_city] = nil
      case_party_hash[:party_state] = nil
      case_party_hash[:party_zip] = nil
    end
    party_hash = party_hash["partyName"] if is_lawyer == 0
    party_name = (is_lawyer == 1) ? party_hash["attorneyName"]["sortName"] : party_hash["sortName"]
    case_party_hash[:case_id] = case_info_hash[:case_id]
    case_party_hash[:court_id] = case_info_hash[:court_id]
    case_party_hash[:is_lawyer] = is_lawyer
    case_party_hash[:party_name] = party_name
    case_party_hash[:party_type] = role
    case_party_hash[:data_source_url] = case_info_hash[:data_source_url]
    case_party_hash[:md5_hash] = MD5Hash.new(:table=>:party).generate(case_party_hash)
    case_party_hash[:run_id] = run_id
    case_party_hash[:touched_run_id] = run_id
    case_party_hash
  end

  def generate_md_hash(data_hash)
    md5_str = ''
    data_hash.each do |k, v|
      md5_str = md5_str + v.to_s
    end
    Digest::MD5.hexdigest md5_str
  end
end
