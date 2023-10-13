# frozen_string_literal: true

require_relative '../models/table_info'
require_relative '../models/table_add_info'
require_relative '../models/table_party'
require_relative '../models/table_activity'
require_relative '../models/table_activity_pdf'
require_relative '../models/table_aws'
require_relative '../models/table_consolidation'
require_relative '../lib/parser'

class ScraperClass < Hamster::Scraper

  SEARCH_URL_SUFIX =  '&resultType=cases&pageSize=100&aAppellateCourt=Both'
  DOMAIN = "https://www.courts.michigan.gov"
  SUB_FOLDER = 'courts_michigan'
  COA_PREFIX = 'https://www.courts.michigan.gov/c/courts/coa/case/'
  MSC_PREFIX = 'https://www.courts.michigan.gov/c/courts/msc/case/'
  
  HEADER = {
    "Authority" => "www.courts.michigan.gov",
    "Accept" => "application/json",
    "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36"
  }

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @parser_obj = ParserClass.new
    @downloaded_files = peon.give_list(subfolder: SUB_FOLDER).map{|e| e.split('.')[0]}
    @already_inserted_links = TableInfo.pluck(:data_source_url)
    @s3 = AwsS3.new(bucket_key = :us_court)
  end
  
  def download
    begin
      save_response
    rescue Exception => e
      puts e.full_message
      report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
    end
  end

  def scrape
    begin
      process_files
    rescue Exception => e
      puts e.full_message
      report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def process_files
    info_a, add_info_a, party_a, activity_a,aws_a, activity_pdf_a, case_consolidation_a = Array.new(7){[]}

    @downloaded_files.each do |case_id|
      puts "processing case_id --> #{case_id}"
      if case_id.include? "msc_"
        link = MSC_PREFIX + case_id
      else  
        link = COA_PREFIX + case_id
      end
      next if @already_inserted_links.include? link
      file_content = peon.give(subfolder: SUB_FOLDER, file: case_id + '.gz')
      info_atemp, add_info_atemp, party_atemp, activity_atemp, aws_atemp, activity_pdf_atemp, case_consolidation_atemp = @parser_obj.parse(file_content)
      puts "processing link --> #{link}"
      upload_file_to_aws(aws_atemp) unless aws_atemp.empty?
      info_a = info_a.append(info_atemp).flatten 
      add_info_a = add_info_a.append(add_info_atemp).flatten
      party_a = party_a.append(party_atemp).flatten
      activity_a = activity_a.append(activity_atemp).flatten
      aws_a = aws_a.append(aws_atemp).flatten
      activity_pdf_a = activity_pdf_a.append(activity_pdf_atemp).flatten
      case_consolidation_a = case_consolidation_a.append(case_consolidation_atemp).flatten
      if info_a.count > 0
        TableInfo.insert_all(info_a) unless info_a.empty?
        TableAddInfo.insert_all(add_info_a) unless add_info_a.empty?
        TableParty.insert_all(party_a) unless party_a.empty?
        TableActivity.insert_all(activity_a) unless activity_a.empty?
        TableAWS.insert_all(aws_a) unless aws_a.empty?
        TableActivityPDF.insert_all(activity_pdf_a) unless activity_pdf_a.empty?
        TableConsolidation.insert_all(case_consolidation_a) unless case_consolidation_a.empty? 
        puts "Inserted #{info_a.count} records"
        info_a, add_info_a, party_a, activity_a,aws_a, activity_pdf_a, case_consolidation_a = Array.new(7){[]}
      end 
    end
  end

  def upload_file_to_aws(aws_atemp)
    aws_atemp.each do |aws_hash| 
      key = aws_hash[:aws_link]
      pdf_url = aws_hash[:source_link]
      response, code = connect_to(pdf_url)
      puts "Pdf file downloaded..!"
      content = response&.body
      @s3.put_file(content, key, metadata={})
      puts "Pdf file uploaded to aws..!"
    end
  end

  def search_url_prefix
    star_date = Date.today - 14
    end_date = Date.today

    star_year = star_date.year.to_i
    star_day = star_date.day.to_i
    star_month = star_date.month.to_i

    end_year = end_date.year.to_i
    end_day = end_date.day.to_i
    end_month = end_date.month.to_i
  
    url = "https://www.courts.michigan.gov/case-search/?filingDate=Custom%20Range%3A#{star_month}%2F#{star_day}%2F#{star_year}%3A#{end_month.to_s}%2F#{end_day.to_s}%2F#{end_year.to_s}&page="
  end

  def save_response
    page = 1
    url_prefix = search_url_prefix
    while true
      url = url_prefix + page.to_s + SEARCH_URL_SUFIX
      header = HEADER
      header["Referer"] = url
      response, code = connect_to(url, header)
      case_ids = @parser_obj.get_inner_links(response.body)
      break if case_ids.empty?
      save_inner_response(case_ids)
      page += 1
    end
  end

  def save_inner_response(case_ids)
    case_ids.each do |case_id|
      file_name = case_id.split("/").last 
      file_name = 'msc_' + file_name if case_id.include? "/msc/"
      next if @downloaded_files.include? file_name
      link = DOMAIN + case_id
      next if @already_inserted_links.include? link
      response, code = connect_to(link)
      data = response.body
      save_file(data, file_name)
      puts "Result saved...!"
    end
  end

  def save_file(data, file_name)
    peon.put content: data, file: file_name, subfolder: SUB_FOLDER
  end

  def connect_to(url, header = {})
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url,  headers: header , proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    return [response, response&.status]
  end

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = response&.status
    puts status == 200 ? status.to_s.greenish : status.to_s.red
    puts '=================================='.yellow
    # end
  end
end
