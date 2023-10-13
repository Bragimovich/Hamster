# frozen_string_literal: true
require_relative '../models/table_info'

class ParserClass < Hamster::Scraper
  DOMAIN = 'https://www.courts.michigan.gov'
  AWS_PREFIX = 'https://court-cases-activities.s3.amazonaws.com/'

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_inner_links(outer_page)
    data = JSON.parse(outer_page)
    case_ids = data["caseSearchResults"]["caseDetailResults"]["searchItems"].map{|e| e['caseUrl']}
  end

  def parse(file_content)
    @info_a, @add_info_a, @party_a, @activity_a, @aws_a, @activity_pdf_a, @case_consolidation_a = Array.new(7){[]}
    @case_details = JSON.parse(file_content)
    coa_case_id = @case_details["courtOfAppealsCaseId"]
    msc_case_id = @case_details["supremeCourtCaseId"]
    link_48 = DOMAIN + "/c/courts/coa/case/#{coa_case_id.to_s}"
    link_49 = DOMAIN + "/c/courts/msc/case/#{msc_case_id.to_s}"
    return if @already_inserted_links.include? link_48 or @already_inserted_links.include? link_49
    consolidations = @case_details["consolidatedCases"]
    handle_coa_parsing(coa_case_id) unless coa_case_id.nil?
    handle_msc_parsing(msc_case_id) unless msc_case_id.nil?
    get_data_case_consolidations(consolidations, coa_case_id, msc_case_id) unless consolidations.nil?
    return [@info_a, @add_info_a, @party_a, @activity_a, @aws_a, @activity_pdf_a, @case_consolidation_a]
  end

  def handle_coa_parsing(case_id)
    court_id = 48
    url_part = "coa"
    call_common_funtions(case_id, court_id, url_part)
  end

  def handle_msc_parsing(case_id)
    court_id = 49
    url_part = "msc"
    call_common_funtions(case_id, court_id, url_part)
  end

  def call_common_funtions(case_id, court_id, url_part)
    get_data_case_info(case_id, court_id, url_part)
    get_data_case_additional_info(case_id, court_id, url_part)
    get_data_case_party(case_id, court_id, url_part)
    get_data_case_activity(case_id, court_id, url_part)
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end

  def get_data_case_consolidations(consolidations, coa_case_id, msc_case_id)
    consolidations = @case_details['consolidatedCases']
    consolidations.each do |con|
      data_hash = {}
      if con['isCourtOfAppealsCase']
        data_hash[:case_id] = coa_case_id
        data_hash[:court_id] = 48
        data_hash[:consolidated_case_id] = con['caseNumber']
        data_hash[:data_source_url] = DOMAIN + "/c/courts/coa/case/#{coa_case_id}"
      else
        data_hash[:case_id] = msc_case_id
        data_hash[:court_id] = 49
        data_hash[:consolidated_case_id] = con['caseNumber']
        data_hash[:data_source_url] = DOMAIN + "/c/courts/msc/case/#{msc_case_id}"
      end
      data_hash[:consolidated_case_name] = con['title']
      data_hash[:consolidated_case_filled_date] = nil
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      @case_consolidation_a << data_hash
    end
  end

  def get_data_case_info(case_id, court_id, url_part)
    data_hash = {}
    data_hash[:case_name] = @case_details["title"]
    data_hash[:case_id] = case_id
    data_hash[:case_filed_date] = @case_details["filingDate"].split("T").first rescue nil
    data_hash[:court_id] = court_id
    data_hash[:case_description] = @case_details['dockets'][0]["comments"] rescue nil
    data_hash[:case_type] = @case_details['dockets'][0]["eventDescription"] rescue nil
    data_hash[:status_as_of_date] = nil
    data_hash[:judge_name] = @case_details["judges"].first 
    data_hash[:lower_case_id] = @case_details["judgments"][0]["trialCourtCaseNumber"] rescue nil
    data_hash[:lower_court_id] = nil
    data_hash[:data_source_url] = DOMAIN + "/c/courts/#{url_part}/case/#{case_id}"
    data_hash[:disposition_or_status] = @case_details["courtOfAppealsStatus"]
    data_hash[:disposition_or_status] = @case_details["supremeCourtStatus"] if court_id == 49
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    @info_a << data_hash
  end

  def get_data_case_additional_info(case_id, court_id, url_part)
    data_hash = {}
    data_hash[:case_id] = case_id
    data_hash[:court_id] = court_id
    data_hash[:lower_court_name] = @case_details["judgments"][0]["trialCourtName"] rescue nil
    data_hash[:lower_case_id] = @case_details["judgments"][0]["trialCourtCaseNumber"] rescue nil
    data_hash[:lower_judge_name] = @case_details["judgments"][0]["trialCourtJudgeName"] rescue nil
    data_hash[:lower_link] = nil
    data_hash[:disposition] = nil
    data_hash[:data_source_url] = DOMAIN + "/c/courts/#{url_part}/case/#{case_id}"
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    @add_info_a << data_hash
  end

  def get_data_case_party(case_id, court_id, url_part)
    all_parties = @case_details["courtOfAppealsParties"]
    all_parties = @case_details["supremeCourtParties"] if court_id == 49
    data_hash = {}
    all_parties.each do |data|
      data_hash = {}
      data_hash[:case_id] = case_id
      data_hash[:is_lawyer] = 0
      data_hash[:party_name] = data["name"]
      data_hash[:party_type] = data["connectionsValue"]
      data_hash[:party_law_firm] = nil
      data_hash[:party_address] = nil
      data_hash[:party_city] = nil
      data_hash[:party_state] = nil 
      data_hash[:party_zip] = nil
      data_hash[:party_description] = nil
      data_hash[:data_source_url] = DOMAIN + "/c/courts/#{url_part}/case/#{case_id}"
      data_hash[:court_id] = court_id 
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      @party_a << data_hash
 
      data_hash_lawyer = {}
      data_hash_lawyer = data_hash.clone
      data_hash_lawyer[:is_lawyer] = 1
      data_hash_lawyer[:party_name] = data['attorneys'][0]["name"] rescue data["name"]
      data_hash_lawyer[:md5_hash] = create_md5_hash(data_hash_lawyer)
      @party_a << data_hash_lawyer
    end
  end

  def get_data_case_activity(case_id, court_id, url_part)
    activities = @case_details["dockets"]
    activities.each do |activity|
      relations_table_flag = false
      data_hash = {}
      data_hash[:case_id] = case_id
      data_hash[:activity_date] = activity["eventDate"].split("T").first  rescue nil
      data_hash[:activity_desc] = activity["comments"]
      data_hash[:activity_type] = activity["eventDescription"]
      file = activity['episerverDocuments'][0]['fileUrl'] rescue nil
      unless file.nil?
      	file = nil if file.include? ".mp3" or file.include? "333263(16)_[untitled].pdf"
      end
      data_hash[:file] = nil
      pdf_on_aws_md5 = ''
      unless file.nil?
        data_hash[:file] = DOMAIN + file
        pdf_on_aws_md5 = pdfs_on_aws(case_id, court_id, url_part, file)
        relations_table_flag = true
      end
      data_hash[:data_source_url] = DOMAIN + "/c/courts/#{url_part}/case/#{case_id}"
      data_hash[:court_id] = court_id
      activity_md5 = create_md5_hash(data_hash)
      data_hash[:md5_hash] = activity_md5
      relations_activity_pdf(activity_md5, pdf_on_aws_md5) if relations_table_flag
      @activity_a << data_hash
    end
  end

  def pdfs_on_aws(case_id, court_id, url_part, file)
    data_hash = {}
    data_hash[:court_id] = court_id
    data_hash[:case_id] = case_id
    data_hash[:source_type] = 'activity'
    pdf_url = DOMAIN + file
    file_name = pdf_url.split('/').last
    key = 'us_courts_expansion_' + court_id.to_s + '_' + case_id.to_s + '_' + file_name
    data_hash[:aws_link] = AWS_PREFIX + key
    data_hash[:source_link] = pdf_url
    data_hash[:data_source_url] = DOMAIN + "/c/courts/#{url_part}/case/#{case_id}"
    pdf_on_aws_md5 = create_md5_hash(data_hash)
    data_hash[:md5_hash] = pdf_on_aws_md5
    @aws_a << data_hash
    return pdf_on_aws_md5
  end
  
  def relations_activity_pdf(activity_md5, pdf_on_aws_md5)
    data_hash = {}
    data_hash[:case_activities_md5] = activity_md5
    data_hash[:case_pdf_on_aws_md5] = pdf_on_aws_md5
    @activity_pdf_a << data_hash
  end
end
