# frozen_string_literal: true
class Parser <  Hamster::Scraper
  COURT_ID = 8
  LOWER_COURT_ID = 446
  SOURCE = "https://www.supremecourt.ohio.gov/Clerk/ecms/#/caseinfo/"

  def initialize(page)
    super
    page == nil ? @html: @html = JSON.parse(page)
  end

  def get_attorney_token(page)
    parsed_page = Nokogiri::HTML(page)
    parsed_page.css("meta")[4].values.last
  end

  def get_attorney_numbers
    @html["Parties"].map{|e| e["Attorneys"]}.reject{|e| e.empty?}.reject{|e| e.nil?}.map{|e| e.map{|k| k["ARNumber"]}}.flatten 
  end

  def case_info(run_id)
    data_array_info = []
    data_hash={}  
    data_hash[:court_id] = COURT_ID
    data_hash[:case_id] = @html["CaseInfo"]["CaseNumber"].squish
    data_hash[:case_name] = @html["CaseInfo"]["Caption"].squish
    data_hash[:case_filed_date] = @html["CaseInfo"]["DateFiled"].split("T").first
    data_hash[:case_type] = @html["CaseInfo"]["CaseType"].squish rescue nil
    data_hash[:status_as_of_date] = "Case is " + @html["CaseInfo"]["Status"].squish
    data_hash[:lower_court_id] = 446
    data_hash[:lower_case_id] = @html["CaseJurisdiction"]["PriorCaseNumbers"][0]["Number"] rescue nil
    if (@html["CaseJurisdiction"]["Name"]!=nil)
      data_hash[:lower_court_id] = LOWER_COURT_ID.to_i + @html["CaseJurisdiction"]["Name"].split(" ").first.split.reject{|e| e.include?"/\d/"}[0].to_i   if @html["CaseJurisdiction"]["Name"].split(" ").first.split.reject{|e| e.include?"/\d/"}[0].to_i != 0
    end
    data_hash[:data_source_url] = SOURCE + data_hash[:case_id].gsub("-","/")
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_array_info.append(data_hash)
    data_array_info
  end

  def case_party(run_id)
    data_array_party = []
    @html["Parties"].each do |party|
      data_hash = {}
      data_hash[:court_id] = COURT_ID
      data_hash[:case_id] = @html["CaseInfo"]["CaseNumber"].squish
      data_hash[:is_lawyer] =  0
      data_hash[:party_name] = party["Name"]
      data_hash[:party_type] = party["Type"]
      data_hash[:data_source_url] = SOURCE + data_hash[:case_id].gsub("-","/")
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_array_party.append(data_hash)
    end  
    data_array_party     
  end 

  def lawyer_info(info)
    data_hash_lawyer = {}
    data_hash_lawyer = info.clone  
    data_hash_lawyer[:party_address] = @html["Address"].squish
    data_hash_lawyer[:party_city] = @html["City"]
    data_hash_lawyer[:party_state] = @html["State"]
    data_hash_lawyer[:party_description] = "https://www.supremecourt.ohio.gov/AttorneySearch/#/#{info[:party_law_firm]}/attyinfo"  
    data_hash_lawyer[:party_zip] = @html["ZipCode"]
    data_hash_lawyer[:party_law_firm] = @html["Employer"]
    data_hash_lawyer[:data_source_url] = SOURCE + data_hash_lawyer[:case_id].gsub("-","/")
    data_hash_lawyer[:md5_hash] = create_md5_hash(data_hash_lawyer)
    data_hash_lawyer
  end

  def case_lawyers(run_id)
    lawyer_array=[]
    @html["Parties"].each do |party|
      next if party["Attorneys"].empty?
      party["Attorneys"].each do |attorney|
        data_hash={}
        data_hash[:court_id] = COURT_ID
        data_hash[:case_id] = @html["CaseInfo"]["CaseNumber"].squish
        data_hash[:is_lawyer] =  1
        data_hash[:party_name] = attorney["Name"]
        data_hash[:party_type] = party["Type"]
        data_hash[:party_law_firm] = attorney["ARNumber"]
        data_hash[:touched_run_id] = run_id
        data_hash[:run_id] = run_id
        lawyer_array.append(data_hash)
      end
    end
    lawyer_array
  end

  def case_activities(run_id)
    data_array_activities =[]
    @html["DocketItems"].each do |docket_record|
      data_hash = {}
      data_hash[:court_id] = COURT_ID
      data_hash[:case_id] = @html["CaseInfo"]["CaseNumber"].squish
      data_hash[:activity_desc] = docket_record["Description"].strip
      data_hash[:activity_desc] = docket_record["Description"].split(".").first.strip if docket_record["Description"].include?"See"
      data_hash[:activity_date] = docket_record["DateFiled"].split("T").first rescue nil
      data_hash[:activity_type] = docket_record["Type"]
      file_number = docket_record["DocumentName"]
      pdf_type = data_hash[:activity_type] == "DOCKET" ? "Docket" : "Decision"
      data_hash[:file] = "https://www.supremecourt.ohio.gov/pdf_viewer/pdf_viewer.aspx?pdf=#{file_number}&subdirectory=#{data_hash[:case_id]}\\#{pdf_type}Items&source=DL_Clerk" unless file_number.empty?
      data_hash[:file] = nil if file_number.empty? 
      data_hash[:data_source_url] = SOURCE + data_hash[:case_id].gsub("-","/")
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:touched_run_id] = run_id
      data_hash[:run_id] = run_id
      data_array_activities.append(data_hash)
    end
    data_array_activities
  end 
  
  def activities_pdfs_on_aws(run_id)
    data_array_pdfs =[]      
    @html["DocketItems"].each do |docket_record|
      data_hash={}
      next if  docket_record["DocumentName"].empty?
      data_hash[:court_id] = COURT_ID
      data_hash[:case_id] = @html["CaseInfo"]["CaseNumber"].squish
      data_hash[:source_type] = "activities"
      file_name = docket_record["DocumentName"]
      key = 'us_courts_expansion_' + COURT_ID.to_s + '_' + data_hash[:case_id].to_s + '_' + file_name 
      data_hash[:aws_link] = key
      pdf_type = docket_record["Type"] == "DOCKET" ? "Docket" : docket_record["Type"] == "DECISION" ? "Decision" : nil
      data_hash[:source_link] =  "https://www.supremecourt.ohio.gov/pdf_viewer/pdf_viewer.aspx?pdf=#{file_name}&subdirectory=#{data_hash[:case_id]}\\#{pdf_type}Items&source=DL_Clerk"
      data_hash[:data_source_url] = SOURCE + data_hash[:case_id].gsub("-","/")
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_array_pdfs.append(data_hash)
    end
    data_array_pdfs
  end

  def case_relations_activity_pdf(activities, pdf_activity)
    case_relations_activities=[]
    activities.each_with_index do |activity_record, index_no|
      data_hash={}
      data_hash[:court_id] = COURT_ID
      data_hash[:case_activities_md5] = activity_record
      data_hash[:case_pdf_on_aws_md5] = pdf_activity[index_no]
      case_relations_activities.append(data_hash)
    end
    case_relations_activities
  end

  def case_additional_info(run_id)
    data_array_additional = []
    return nil if (@html["CaseJurisdiction"]["PriorCaseNumbers"].nil?) || (@html["CaseJurisdiction"]["PriorCaseNumbers"].empty?)
    @html["CaseJurisdiction"]["PriorCaseNumbers"].each do |row|
      data_hash = {}
      data_hash[:court_id] = COURT_ID
      data_hash[:case_id] = @html["CaseInfo"]["CaseNumber"] 
      data_hash[:lower_court_id] = nil
      data_hash[:lower_court_id] = LOWER_COURT_ID.to_i + @html["CaseJurisdiction"]["Name"].split(" ").first.split.reject{|e| e.include?"/\d/"}[0].to_i   if @html["CaseJurisdiction"]["Name"].split(" ").first.split.reject{|e| e.include?"/\d/"}[0].to_i != 0
      data_hash[:lower_court_name]= @html["CaseJurisdiction"]["County"].gsub("(None)","")+ " " + @html["CaseJurisdiction"]["Name"]
      data_hash[:lower_case_id] = row["Number"]
      data_hash[:lower_judgement_date] = @html["CaseJurisdiction"]["PriorDecisionDate"].split("T").first rescue nil
      data_hash[:data_source_url] = SOURCE + data_hash[:case_id].gsub("-","/")
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      data_array_additional.append(data_hash)
    end
    data_array_additional
  end

  private

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end
end

