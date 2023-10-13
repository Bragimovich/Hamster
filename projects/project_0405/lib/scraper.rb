# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../models/dc_ac_case_runs'
require_relative '../models/dc_ac_case_info'
require_relative '../models/dc_ac_case_consolidations'
require_relative '../models/dc_ac_case_additional_info'
require_relative '../models/dc_ac_case_party'
require_relative '../models/dc_ac_case_activities'
require_relative '../models/dc_ac_case_relations_activity_pdf'
require_relative '../models/dc_ac_case_relations_info_pdf'
require_relative '../models/dc_ac_case_pdfs_on_aws'

class Scraper <  Hamster::Scraper

  DOMAIN = "https://efile.dcappeals.gov"
  SUB_PATH="/public/caseSearch.do" 
  SUB_FOLDER = "court_data"

  HEADERS = 
  { 
    "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
    "Accept-Language" => "en-US,en;q=0.9",
    "Cache-Control" => "max-age=0",
    "Connection" => "keep-alive",
    "Referer" => "https://efile.dcappeals.gov/public/publicActorSearch.do",
    "Sec-Fetch-Dest" => "document",
    "Sec-Fetch-Mode" => "navigate",
    "Sec-Fetch-Site" => "same-origin",
    "Sec-Fetch-User" => "?1",
    "Upgrade-Insecure-Requests" => "1",
    "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.41 Safari/537.36",
    "Sec-Ch-Ua" => "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"101\", \"Google Chrome\";v=\"101\"",
    "Sec-Ch-Ua-Mobile" => "?0",
    "Sec-Ch-Ua-Platform" => "\"Linux\""
  }
  
  def initialize
    super
    @proxy_filter            = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @parser_obj              = Parser.new
    @run_id = run
    @s3 = AwsS3.new(bucket_key = :us_court)
  end
  
  def download
    url = DOMAIN + SUB_PATH
    start_date          = DcAcCaseInfo.where(case_filed_date: DcAcCaseInfo.select('MAX(case_filed_date)')).pluck(:case_filed_date)[0].strftime("%m/%d/%Y").gsub("/" , "%2F")
    end_date            = Time.now.strftime("%m/%d/%Y").gsub("/" , "%2F")
    body                = prepare_body(start_date, end_date)
    inner_page_response = connect_to(url, headers:HEADERS, req_body:body, method: :post, proxy_filter: @proxy_filter)
    updated_data_links  = DcAcCaseInfo.where("status_as_of_date != 'Decided/Dismissed' and deleted = 0").pluck(:data_source_url)
    already_downloaded_files_array = peon.give_list(subfolder: "#{@run_id.run_id}_court_data")
    links = @parser_obj.get_inner_links(inner_page_response.body).map{|a| a = DOMAIN + a }
    links = links + updated_data_links
    links.uniq.each do |link|
      file_name_detail = Digest::MD5.hexdigest link
      puts "================== name     #{file_name_detail}"
      next if already_downloaded_files_array.include? file_name_detail + '.gz'
      details_response = connect_to(link)
      pdf_names = @parser_obj.fetch_pdf_names(details_response.body)
      cookie =  details_response.headers["set-cookie"]
      download_pdfs(pdf_names, link, cookie) unless pdf_names.empty?
      save_file(details_response, file_name_detail, "#{@run_id.run_id}_#{SUB_FOLDER}")
    end
  end

  def parse
    downloaded_files = peon.give_list(subfolder: "#{@run_id.run_id}_#{SUB_FOLDER}")
    downloaded_files.each do |file_name|
      file_content_brief = peon.give(subfolder: "#{@run_id.run_id}_#{SUB_FOLDER}", file: file_name)
      case_info, case_consolidations, case_additional_info, us_case_party, us_case_activities = @parser_obj.get_inner_data(file_content_brief, @run_id.run_id)
      next if case_info.nil?
      DcAcCaseInfo.insert(case_info)                           unless case_info.empty?
      DcAcCaseConsolidations.insert_all(case_consolidations)   unless case_consolidations.empty?
      DcAcCaseAdditionalInfo.insert(case_additional_info)      unless case_additional_info.nil?
      DcAcCaseParty.insert_all(us_case_party)                  unless us_case_party.empty?
      DcAcCaseActivities.insert_all(us_case_activities)        unless us_case_activities.empty?
      delete_old_parties(us_case_party)                        unless us_case_party.empty?
      pdf_names = @parser_obj.fetch_pdf_names(file_content_brief)
      pdf_on_aws_hashes_array = []
      pdf_on_aws_pdf_relations_array = []
      unless pdf_names.empty?
        all_pdfs_files = peon.give_list(subfolder: "pdfs")
        pdf_names.each do |pdf_name|
          start_name = pdf_name.split(":")[1..].join("_")
          file_name = all_pdfs_files.select {|f| f.start_with? start_name}[0]
          next if file_name.nil?

          pdf_content = peon.give(subfolder: "pdfs", file: file_name)
          pdf_url_link = "https://efile.dcappeals.gov/document/view.do?documentID=#{file_name.split("_")[2].gsub(".gz","")}&csIID=#{file_name.split("_")[1]}"
          activities_pdfs_on_aws_hash = @parser_obj.activities_pdfs_on_aws(pdf_url_link, case_info, "activity", file_name.split("_")[2].gsub(".gz",""))
          activity_number = @parser_obj.find_activity_index(file_content_brief, start_name)
          activity_md5_hash =  us_case_activities[activity_number][:md5_hash]
          pdf_on_aws_md5_hash =  activities_pdfs_on_aws_hash[:md5_hash]
          data_relations_activity_hash = @parser_obj.case_relations_activity_pdf(pdf_on_aws_md5_hash, activity_md5_hash)
          pdf_on_aws_pdf_relations_array << data_relations_activity_hash
          pdf_data_hash = aws_upload(activities_pdfs_on_aws_hash, pdf_content, "activity")
          pdf_on_aws_hashes_array << pdf_data_hash
        end
      end
      info_aws_data_hash = @parser_obj.activities_pdfs_on_aws(case_info[:data_source_url], case_info, "info", "info.html")
      info_aws_data_hash = aws_upload(info_aws_data_hash, file_content_brief, "info")
      pdf_md5 = info_aws_data_hash[:md5_hash]
      info_md5 = case_info[:md5_hash]
      data_relations_info_hash =  @parser_obj.case_relations_info_pdf(pdf_md5, info_md5)
      pdf_on_aws_hashes_array << info_aws_data_hash
      DcScCasePdfsOnAws.insert_all(pdf_on_aws_hashes_array) unless pdf_on_aws_hashes_array.empty?
      DcAcCaseRelationsActivityPdf.insert_all(pdf_on_aws_pdf_relations_array) unless pdf_on_aws_pdf_relations_array.empty?
      DcAcCaseRelationsInfoPdf.insert(data_relations_info_hash) unless data_relations_info_hash.nil?
    end
    mark_deleted
    @run_id.finish
  end

  private

  def delete_old_parties(us_case_party)
    new_hashes = us_case_party.map { |e| e[:md5_hash]}
    already_inserted_parties = DcAcCaseParty.where(case_id: us_case_party[0][:case_id])
    old_parties_ids = already_inserted_parties.reject { |e| new_hashes.include? e[:md5_hash]}.map { |e| e[:id] }
    DcAcCaseParty.where(:id => old_parties_ids).update_all(:deleted => 1) unless old_parties_ids.empty?
  end

  def prepare_body(start_date, end_date)
    "action=&csNumber=&shortTitle=&lcCsNumber=&fromDt=#{start_date}&toDt=#{end_date}&startRow=1&displayRows=9999&orderBy=CsNumber&orderDir=DESC&href=%2Fpublic%2FcaseView.do&submitValue=Search"
  end

  def download_pdfs(pdf_names, url, cookie)
    all_pdfs_files = peon.give_list(subfolder: "pdfs")
    links_array = []
    pdf_names.each do |pdf_name|
      form_data = form_data_gen(cookie, url, pdf_name)
      form_data = form_data.to_a.map { |val| val[0] + "=" + val[1] }.join("&")
      headers = HEADERS
      headers = headers.merge({
        "Accept" => "*/*",
        "Origin" => "https://efile.dcappeals.gov",
        "Referer" => url,
        "Cookie" => cookie,
       })
      pdf_url = "https://efile.dcappeals.gov/dwr/call/plaincall/AJAX.getViewDocumentLinks.dwr"
      response = connect_to(pdf_url, headers: headers, req_body:form_data, method: :post, proxy_filter: @proxy_filter)
      pd_link = response.body.split('"')[2].gsub("amp\;","")[..-2]
      links_array << "https://efile.dcappeals.gov#{pd_link}"
    end

    links_array.each_with_index do |link, index|
      next if link.include? "#"

      file_name_detail =  "#{pdf_names[index].split(":")[1..].join("_")}_#{link.split("=")[1].split("&")[0]}"
      next if all_pdfs_files.include? file_name_detail

      response =  connect_to(url:link){ |resp| resp.headers[:content_type].match?(%r{application/octet-stream|text|html|json}) }
      ###########  file_name_detail PATTREN (file key on resource + case id + file key in url) ###############
      save_file(response, file_name_detail, "pdfs")
    end
  end

  def upload_file_to_aws(aws_data, pdf)
    aws_url = "https://court-cases-activities.s3.amazonaws.com/"
    if aws_data[:aws_link].nil?
      key = aws_data[:aws_html_link]
    else
      return aws_url + aws_data[:aws_link] unless @s3.find_files_in_s3(aws_data[:aws_link]).empty?
      key = aws_data[:aws_link]
    end
    @s3.put_file(pdf, key, metadata={})
  end

  def aws_upload(pdf_hash, pdf, type)
    if type == 'activity'
      pdf_hash[:aws_link] = upload_file_to_aws(pdf_hash, pdf)
    else
      pdf_hash[:aws_html_link] = upload_file_to_aws(pdf_hash, pdf)
    end
    pdf_hash
  end

  def mark_deleted
    delete_old_records(DcAcCaseInfo)
    delete_old_records(DcAcCaseAdditionalInfo)
  end

  def delete_old_records(model)
    ids_extract = model.where(:deleted => 0).group(:data_source_url).having("count(*) > 1").pluck("data_source_url, GROUP_CONCAT(id)")
    all_old_ids = []
    ids_extract.each do |value|
      ids = value[-1].split(",").map(&:to_i)
      ids.delete get_max(ids)
      all_old_ids << ids
    end
    all_old_ids = all_old_ids.flatten
    model.where(:id => all_old_ids).update_all(:deleted => 1)
  end

  def get_max(value)
    value.max
  end

  def save_file(content, file_name, subfolder)
    peon.put content: content.body, file: file_name, subfolder: subfolder
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = response&.status
    puts status == 200 ? status.to_s.greenish : status.to_s.red
    puts '=================================='.yellow
  end

  def form_data_gen(cookie, url, link)
    form_data = {
      "callCount" => 1.to_s,
      "page" => "",
      "httpSessionId" => "#{url.split(".gov")[1]}",
      "scriptSessionId" => "#{cookie.split("ID=")[1].split("\;")[0]}",
      "c0-scriptName" => "AJAX",
      "c0-methodName" => "getViewDocumentLinks",
      "c0-id" => "0",
      "c0-param0" => "string:#{link.split(":")[0]}",
      "c0-param1" => "string:#{link.split(":")[1]}",
      "c0-param2" => "string:#{link.split(":")[2]}",
      "batchId" => "0",
    }
  end

  def run
    RunId.new(DcAcCaseRuns)
  end
end
