# frozen_string_literal: true
require_relative '../models/ky_saac_case_party'
require_relative '../models/ky_saac_case_additional_info'
require_relative '../models/ky_saac_case_info'
require_relative '../models/ky_saac_case_activities'
require_relative '../models/ky_saac_case_relations_activity_pdf'
require_relative '../models/ky_saac_case_pdfs_on_aws'
require_relative '../models/ky_saac_case_runs'
require_relative '../lib/parser'

class Scraper < Hamster::Scraper

  URL_PREFIX = "https://appellatepublic.kycourts.net/api/api/v1/cases/search?queryString=true&searchFields%5B0%5D.searchType=Starts%20With&searchFields%5B0%5D.operation=%3D&searchFields%5B0%5D.values%5B0%5D="
  URL_POSTFIX = "&searchFields%5B0%5D.indexFieldName=caseNumber"
  PDF_URL = "https://appellatepublic.kycourts.net/api/api/v1/publicaccessdocuments?filter=parentCategory%3Ddocketentries%2CparentID%3D"
  URL = "https://appellatepublic.kycourts.net/api/api/v1/publicaccessdocuments/"
 
  def initialize
    super
    @agent = Mechanize.new
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @parser = Parser.new
    @run_id = run
  end

  def run_task
    scraper
    store
  end

  def scraper
    ids_array = []
    year = Date.today.year.to_s
    start_index = 1
    page_no = 1
    url = URL_PREFIX + year + URL_POSTFIX
    while true
      response = send_request(url, page_no, start_index)
      break if @parser.links_count(response) == 0
      ids = @parser.get_links(response)
      ids_array = ids_array + ids
      start_index += 100
      page_no += 1 
    end
    ids_array = ids_array + updated_record_ids
    download(ids_array.uniq, @run_id.run_id)
  end

  def create_md5_arrays
    @info_md5_array = []
    @activity_md5_array = []
    @aws_md5_array = []
    @add_info_md5_array = []
    @party_md5_array = []
    @relation_md5_array = []
  end

  def store
    @s3 = AwsS3.new(bucket_key = :us_court, account = :us_court)
    create_md5_arrays
    previous_records = KySaacCaseInfo.where(touched_run_id: @run_id.run_id).pluck(:md5_hash)
    subfolder = "data#{@run_id.run_id}"
    dataset = Dir["#{storehouse}store/#{subfolder}/*"].map{|e| e.split("/").last}
    dataset.each do |data_dir|
      case_info_response = peon.give(file: "case_info_response", subfolder: "#{subfolder}/#{data_dir}")
      lower_coat_response =  peon.give(file: "lower_coat_response", subfolder: "#{subfolder}/#{data_dir}")
      case_info_hash = @parser.case_info_parser(case_info_response, lower_coat_response)
      next if (case_info_hash.empty?) || (previous_records.include? case_info_hash[:md5_hash])

      case_info_hash["run_id"] = @run_id.run_id
      case_info_hash["touched_run_id"] = @run_id.run_id
      parties_response = peon.give(file: "parties_response", subfolder: "#{subfolder}/#{data_dir}")
      case_party_array = @parser.case_party_parser(parties_response, case_info_hash,@run_id.run_id)
      lower_coat_response = peon.give(file: "lower_coat_response", subfolder: "#{subfolder}/#{data_dir}")
      case_additional_array = @parser.case_additional_info(lower_coat_response, case_info_hash,@run_id.run_id)
      docket_response = peon.give(file: "docket_response", subfolder: "#{subfolder}/#{data_dir}")
      activities_array, case_pdfs_on_aws_array, case_relations_activity_pdf_array = case_activities_parser(docket_response, case_info_hash, subfolder, data_dir)
      insertion_handler(case_info_hash, case_party_array,case_additional_array, activities_array, case_pdfs_on_aws_array, case_relations_activity_pdf_array)
    end
    mark_deleted
    @run_id.finish
  end

  private

  def send_request(url, page_no, start_index, retries = 3)
    begin
      uri = URI.parse("#{url}")
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json, text/plain, */*"
      request["Connection"] = "keep-alive"
      request["Referer"] = "https://appellatepublic.kycourts.net/search/case?q=true&advanced=true&p.page=#{page_no}"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36"
      request["X-Ctrack-Excludeselflinks"] = "true"
      request["X-Ctrack-Paging-Calculatetotalcount"] = "true"
      request["X-Ctrack-Paging-Maxresults"] = "100"
      request["X-Ctrack-Paging-Startindex"] = "#{start_index}"
      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue Exception => e
      if retries <= 1
        raise
      end
      send_request(url, page_no, start_index, retries -1)
    end
  end

  def updated_record_ids
    KySaacCaseInfo.where("disposition_or_status != 'FINAL'").pluck(:data_source_url).map{|r| r = r.split("/").last}
  end

  def download(ids, subfolder)
    all_files = peon.list(subfolder: subfolder) rescue []
    ids.each do |id|
      next if all_files.include? id

      responses = {
        case_info_response: case_info(id)&.body,
        docket_response: docket_enteries(id)&.body,
        parties_response: parties(id)&.body,
        lower_coat_response: lower_coat(id)&.body
      }
      save_file(responses, id, subfolder)
    end
  end

  def inner_headers(id)
    headers = {
      "Accept" => "application/json, text/plain, */*",
      "Connection" => "keep-alive",
      "Referer" => "https://appellatepublic.kycourts.net/case/summary/#{id}",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36",
      "X-Ctrack-Excludeselflinks" => "true",
      "X-Ctrack-Paging-Calculatetotalcount" => "true",
      "X-Ctrack-Paging-Maxresults" => "100",
      "X-Ctrack-Paging-Startindex" => "1"
    }
  end

  def case_info(id)
    url = "https://appellatepublic.kycourts.net/api/api/v1/cases/#{id}"
    connect_to(url:url,headers:inner_headers(id))
  end

  def docket_enteries(id)  
    headers = inner_headers(id).merge({
      "X-Ctrack-Paging-Orderby" => "filedDate desc"
    })
    url = "https://appellatepublic.kycourts.net/api/api/v1/cases/#{id}/docketentries"
    connect_to(url:url, headers:headers)
  end

  def parties(id)
    headers = inner_headers(id).merge({
      "X-Ctrack-Paging-Orderby" => "orderBy asc"
    })
    url = "https://appellatepublic.kycourts.net/api/api/v1/cases/#{id}/parties"
    connect_to(url:url, headers:headers)
  end

  def lower_coat(id)
    headers = inner_headers(id).merge({
      "X-Ctrack-Paging-Orderby" =>  "lowerCourtCaseNumber.raw asc"
    })
    url = "https://appellatepublic.kycourts.net/api/api/v1/cases/#{id}/lowercourts"
    connect_to(url:url, headers:headers)
  end

  def save_file(responses, id, subfolder)
    sub_folder = "#{storehouse}store/#{subfolder}"
    FileUtils.mkdir(sub_folder) unless Dir.exist?(sub_folder)
    dataset_folder = "#{storehouse}store/#{subfolder}/#{id}"
    FileUtils.mkdir(dataset_folder) unless Dir.exist?(dataset_folder)
    responses.each do |key, value|
      peon.put content: value, file: key.to_s, subfolder: "#{subfolder}/#{id}"
    end
  end

  def upload_file(file_key, case_info_hash)
    aws_url = "https://court-cases-activities.s3.amazonaws.com/"
    key = "us_courts_expansion_#{case_info_hash[:court_id]}_#{case_info_hash[:case_id].split.join("_")}_#{file_key}.pdf"
    return aws_url + key unless @s3.find_files_in_s3(key).empty?

    file = URL + file_key + "/download"
    response = connect_to(file)
    @s3.put_file(response.body, key, metadata={})
  end

  def case_activities_parser(file, case_info_hash, subfolder, data_dir)
    activities_array = []
    case_pdfs_on_aws_array = []
    case_relations_activity_pdf_array = []
    case_activities_response = @parser.parse_content(file)
    return [[], [], []] if case_activities_response.empty?
    case_activities_response.each do |activity|
      if activity["hasDocuments"] == true
        response = connect_to(PDF_URL+activity["docketEntryID"])
        file_key = @parser.file_key(response)
        file = URL + file_key + "/download"
        aws_link = upload_file(file_key, case_info_hash)
        case_pdfs_on_aws_hash = @parser.case_pdfs_on_aws_parser(case_info_hash, file, aws_link, @run_id.run_id)
      else
        file = nil
        case_pdfs_on_aws_hash = {}
      end

      case_activity_hash, case_relations_activity_pdf = @parser.case_activities_info(case_info_hash, activity, file, @run_id.run_id, case_pdfs_on_aws_hash)

      if file
        case_pdfs_on_aws_array << case_pdfs_on_aws_hash
        case_relations_activity_pdf_array << case_relations_activity_pdf
      end
      activities_array << case_activity_hash
    end
    [activities_array, case_pdfs_on_aws_array, case_relations_activity_pdf_array]
  end

  def insertion_handler(case_info_hash, case_party_array, case_additional_array, activities_array, case_pdfs_on_aws_array, case_relations_activity_pdf_array)
    @info_md5_array << case_info_hash[:md5_hash]
    @add_info_md5_array = @add_info_md5_array + case_additional_array.map { |e| e[:md5_hash]}
    @activity_md5_array = @activity_md5_array + activities_array.map { |e| e[:md5_hash]}
    @aws_md5_array = @aws_md5_array + case_pdfs_on_aws_array.map { |e| e[:md5_hash]}
    @party_md5_array = @party_md5_array + case_party_array.map { |e| e[:md5_hash]}
    @relation_md5_array = @relation_md5_array + case_relations_activity_pdf_array.map { |e| e[:md5_hash]}
    KySaacCaseInfo.insert(case_info_hash) unless case_info_hash.empty?
    KySaacCaseAdditionalInfo.insert_all(case_additional_array) unless case_additional_array.empty?
    KySaacCaseParty.insert_all(case_party_array) unless case_party_array.empty?
    KySaacCaseActivities.insert_all(activities_array) unless activities_array.empty?
    KySaacCasePdfsOnAws.insert_all(case_pdfs_on_aws_array) unless case_pdfs_on_aws_array.empty?
    KyCaseRelationsActivityPdf.insert_all(case_relations_activity_pdf_array) unless case_relations_activity_pdf_array.empty?
    update_touch_run_id if @info_md5_array.count > 20
  end

  def update_touch_run_id
    KySaacCaseInfo.where(md5_hash: @info_md5_array).update_all(:touched_run_id => @run_id.run_id)
    KySaacCaseAdditionalInfo.where(md5_hash: @add_info_md5_array).update_all(:touched_run_id => @run_id.run_id)
    KySaacCaseParty.where(md5_hash: @party_md5_array).update_all(:touched_run_id => @run_id.run_id)
    KySaacCaseActivities.where(md5_hash: @activity_md5_array).update_all(:touched_run_id => @run_id.run_id)
    KySaacCasePdfsOnAws.where(md5_hash: @aws_md5_array).update_all(:touched_run_id => @run_id.run_id)
    KyCaseRelationsActivityPdf.where(md5_hash: @relation_md5_array).update_all(:touched_run_id => @run_id.run_id)
    create_md5_arrays
  end

  def mark_deleted
    KySaacCaseInfo.where.not(touched_run_id: @run_id.run_id).where("status_as_of_date != 'FINAL'").update_all(deleted: 1)
    case_ids = KySaacCaseInfo.where.not(touched_run_id: @run_id.run_id).where("status_as_of_date != 'FINAL'").pluck(:case_id)
    models = [KySaacCaseActivities, KySaacCaseAdditionalInfo, KySaacCaseParty, KySaacCasePdfsOnAws]
    models.each do |model|
      model.where.not(touched_run_id: @run_id.run_id).where(case_id: case_ids).update_all(deleted: 1)
    end
    aws_md5_hashes = KySaacCasePdfsOnAws.where(deleted: 1).pluck(:md5_hash)
    KyCaseRelationsActivityPdf.where(case_pdf_on_aws_md5: aws_md5_hashes).update_all(deleted: 1)
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

  def mechanize_connect(url, headers, retries = 10)
    begin
      response = @agent.get(url, headers)
      response
    rescue Exception => e
      if retries <= 1
        raise
      end
      mechanize_connect(url, headers, retries - 1)
    end
  end

  def run
    RunId.new(KySaacCaseRuns)
  end
end
