require_relative '../lib/parser'
require_relative '../models/oh_sc_case_additional_info'
require_relative '../models/oh_sc_case_activities'
require_relative '../models/oh_sc_case_info'
require_relative '../models/oh_sc_case_party'
require_relative '../models/oh_sc_case_pdfs_on_aws'
require_relative '../models/oh_sc_case_relations_activity_pdf'
require_relative '../models/oh_sc_case_runs'

class Scraper <  Hamster::Scraper
  SOURCE = "https://www.supremecourt.ohio.gov/Clerk/ecms/Ajax.ashx"
  INNER_URL  = "https://www.supremecourt.ohio.gov/AttorneySearch/Ajax.ashx"
  ATTORNEY_FOLDER = "lawyers"

  HEADERS = 
  {
    "Authority" => "www.supremecourt.ohio.gov",
    "Accept" => "*/*",
    "Accept-Language" => "en-US,en;q=0.9",
    "Origin" => "https://www.supremecourt.ohio.gov",
    "Sec-Ch-Ua" => "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"100\", \"Google Chrome\";v=\"100\"",
    "Sec-Ch-Ua-Mobile" => "?0",
    "Sec-Ch-Ua-Platform" => "\"Linux\"",
    "Sec-Fetch-Dest" => "empty",
    "Sec-Fetch-Mode" => "cors",
    "Sec-Fetch-Site" => "same-origin",
    "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36",
    "X-Requested-With" => "XMLHttpRequest", 
  }

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @s3 = AwsS3.new(bucket_key = :us_court)
    @downloaded_lawyers = peon.give_list(subfolder: ATTORNEY_FOLDER)
    @already_inserted_case = OhScCaseInfo.pluck(:case_id)
    @run_object = RunId.new(OhScCaseRuns)
    @sub_folder =  @run_object.run_id + 1
    @download_status = OhScCaseRuns.pluck(:download_status).last
  end

  def run_script
    (@download_status == "finish") ? store : download
  end
  
  def download
    token_url = "https://www.supremecourt.ohio.gov/Clerk/ecms/scripts/dist/site.min.js?ver=3"
    response = connect_to(token_url)
    main_page_refer = "https://www.supremecourt.ohio.gov/Clerk/ecms/"
    token_value = response.body.split(",")[5].split(":").last.scan(/\w/).join("")
    main_headers = HEADERS
    main_headers = main_headers.merge({"X-Csrf-Token": token_value})
    main_headers = main_headers.merge({"Referer": main_page_refer})
    attorney_headers = get_attorney_token

    start_year = OhScCaseInfo.maximum(:case_filed_date).year
    end_year = Date.today.year

    (start_year..end_year).each do |year|
      download_new_data(year, main_headers, attorney_headers)
    end
    download_updated_records
    finish_download
    store if  (@download_status == "finish")
  end

  def store
    parse_files_data
    mark_deleted
    @run_object.finish if (@download_status == "finish")
  end

  private

  def prepare_inner_body(case_number, year)
    "paramCaseNumber=#{case_number}&paramCaseYear=#{year}&isLoading=true&action=GetCaseDetails&caseId=0&caseNumber=&caseType=&dateFiled=&caseStatus=&caseCaption=&priorJurisdiction=&showParties=false&showDocket=true&showDecision=false&showIssues=false&subscriptionId=&subUserId=&noResult=false&isSealed=false"
  end

  def attorney_form_body(attorney_reg_no)
    "regNumber=#{attorney_reg_no}&action=GetAttyInfo&attyNumber=0&searchResults="
  end

  def get_attorney_token
    parser = Parser.new(nil)
    token_page = connect_to("https://www.supremecourt.ohio.gov/AttorneySearch/")
    token_value = parser.get_attorney_token(token_page.body)
    attorney_page_refer = "https://www.supremecourt.ohio.gov/AttorneySearch/"
    attorney_headers = HEADERS
    attorney_headers = attorney_headers.merge({"x-csrf-token": token_value})
    attorney_headers = attorney_headers.merge({"Referer": attorney_page_refer})
  end
  
  def get_lawyers_data(lawyers, case_id)
    data_lawyer = []
    lawyers.each do |l|
      next if l[:party_law_firm] == "0"
      lawyer_id = l[:party_law_firm]
      page = peon.give(subfolder:ATTORNEY_FOLDER , file: "#{lawyer_id}.gz")
      parser = Parser.new(page)
      data_lawyer.append(parser.lawyer_info(l))
     end 
    data_lawyer
  end

  def parse_files_data
    total_case = peon.give_list(subfolder:"Run_Id_#{@sub_folder}").sort
    run_id = @run_object.run_id
    total_case.each do |case_id|
      case_id_page = peon.give(subfolder:"Run_Id_#{@sub_folder}" , file: case_id)
      next if case_id_page.include?"Sealed"
      next unless case_id_page.include?"UserID"
      parser = Parser.new(case_id_page)
      data_array_info = parser.case_info(run_id)
      data_party_info = parser.case_party(run_id)
      data_additional = parser.case_additional_info(run_id)
      data_activities = parser.case_activities(run_id)
      data_array_pdfs = parser.activities_pdfs_on_aws(run_id)
      pdf_md5_array = data_array_pdfs.map{|e| e[:md5_hash]}
      activities_md5_hash = data_activities.select{|e| e[:file]!=nil}.map{|e| e[:md5_hash]}
      data_relations_activity = parser.case_relations_activity_pdf(activities_md5_hash, pdf_md5_array)
      lawyers = parser.case_lawyers(run_id)
      data_lawyer = get_lawyers_data(lawyers,case_id)
      data_array_pdfs = aws_upload(data_array_pdfs)
      OhScCaseInfo.insert_all(data_array_info)
      OhScCaseActivities.insert_all(data_activities)
      OhScCaseAdditionalInfo.insert_all(data_additional) unless data_additional.nil?
      OhScCasePdfsOnAws.insert_all(data_array_pdfs) unless data_array_pdfs.nil?
      OhScCaseParty.insert_all(data_party_info) unless data_party_info.nil?
      OhScCaseParty.insert_all(data_lawyer) unless data_lawyer.empty?
      OhScCaseRelationsActivityPdf.insert_all(data_relations_activity) unless data_relations_activity.nil?
    end
  end

  def save_file_cases(response, file_name)
    peon.put content:response, file: file_name.to_s, subfolder:"Run_Id_#{@sub_folder}"
  end

  def save_file_cases_attorney(response, file_name)
    peon.put content:response, file: file_name.to_s, subfolder: ATTORNEY_FOLDER.to_s
  end

  def get_case_id(case_id, year)
    "#{year}-#{case_id.rjust(4, '0')}"
  end

  def download_attorney_info(attorney_numbers, attorney_headers)
    attorney_numbers.each do |attorney_number|
      next if @downloaded_lawyers.include? attorney_number+".gz"
      second_inner_body = attorney_form_body(attorney_number)
      second_inner_response = connect_to(INNER_URL, headers:attorney_headers, req_body:second_inner_body, method: :post, proxy_filter: @proxy_filter)      
      save_file_cases_attorney(second_inner_response.body, attorney_number.to_s)
      @downloaded_lawyers.append(attorney_number+".gz")
    end
  end

  def download_inner_pages(year, main_headers, attorney_headers, case_id)
    case_id == 103 ? case_id = 104 : case_id
    inner_body = prepare_inner_body(case_id.to_s, year)
    inner_response = connect_to(SOURCE, headers:main_headers, req_body:inner_body, method: :post, proxy_filter: @proxy_filter)
    unless inner_response.body.include?"Too many results"
      save_file_cases(inner_response.body, "#{year}-#{case_id}")
      parser = Parser.new(inner_response.body)
      unless inner_response.body.include?"Sealed"
        attorney_numbers = parser.get_attorney_numbers
        download_attorney_info(attorney_numbers, attorney_headers)
      end
    end
    inner_response.body
  end

  def download_new_data(year, main_headers, attorney_headers)
    empty_records_count = 0
    already_downloaded_files = peon.give_list(subfolder:"Run_Id_#{@sub_folder}")
    case_id = 1
    while empty_records_count < 20
      if (@already_inserted_case.include? get_case_id(case_id.to_s, year)) || (already_downloaded_files.include? "#{year}-#{case_id}.gz")
        case_id+=1
        next
      end
      response = download_inner_pages(year, main_headers, attorney_headers, case_id)
      if response.include?"Too many results"
        empty_records_count = empty_records_count + 1
        case_id += 1
        next
      end
      empty_records_count = 0
      case_id+=1
    end
  end

  def download_updated_records
    already_downloaded_files = peon.give_list(subfolder:"Run_Id_#{@sub_folder}")
    token_url = "https://www.supremecourt.ohio.gov/Clerk/ecms/scripts/dist/site.min.js?ver=3"
    response = connect_to(token_url)
    token_value = response.body.split(",")[5].split(":").last.scan(/\w/).join("")
    main_headers = HEADERS
    main_page_refer = "https://www.supremecourt.ohio.gov/Clerk/ecms/"
    main_headers = main_headers.merge({"X-Csrf-Token": token_value})
    main_headers = main_headers.merge({"Referer": main_page_refer})
    attorney_headers = get_attorney_token
    case_ids = OhScCaseInfo.select(:case_id).where(deleted: 0).where.not(status_as_of_date: 'Case is Disposed')
    case_ids.each do |case_id|
      year = case_id[:case_id].split("-").first
      id = case_id[:case_id].split("-").last
      next if already_downloaded_files.include? "#{year}-#{id}.gz"
      download_inner_pages(year, main_headers, attorney_headers, id)
    end
  end

  def mark_deleted
    records = OhScCaseInfo.where(deleted: 0).group(:data_source_url).having("count(*) > 1")
    records.each do |record|
      record.update(deleted: 1)
    end
  end

  def upload_file_to_aws(aws_atemp)
    aws_url = "https://court-cases-activities.s3.amazonaws.com/"
    return aws_url + aws_atemp[:aws_link] unless @s3.find_files_in_s3(aws_atemp[:aws_link]).empty?
    key = aws_atemp[:aws_link]
    pdf_url = aws_atemp[:source_link]
    response, code = connect_to(pdf_url)
    content = response&.body
    @s3.put_file(content, key, metadata={})
  end

  def aws_upload(array_pdfs)
    array_pdfs.each do |k|
      k[:aws_link] = upload_file_to_aws(k)
    end
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

  def finish_download
    current_run = OhScCaseRuns.find_by(id: @run_object.run_id)
    current_run.update download_status: 'finish'
    @download_status = 'finish'
  end

end

