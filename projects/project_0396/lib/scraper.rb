# frozen_string_literal: true

require_relative '../models/federal_register_forecasted_notices'
require_relative '../lib/parser'
require_relative '../models/federal_register_forecasted_notices_run'

class ScraperClass < Hamster::Scraper
  
  JSON_URL = 'https://www.federalregister.gov/api/v1/public-inspection-documents.json?conditions%5Btype%5D%5B%5D=NOTICE'
  FILE_NAME = 'results'
  SUB_FOLDER = 'federal_register'

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @parser_obj = ParserClass.new
    @s3 = AwsS3.new(bucket_key = :loki , account = :loki)
    @already_inserted_links = FederalRegisterForecastedNotices.pluck(:link)
    @run_id = run
  end
  
  def download
    page_no = 1
    while true
      begin
        puts "Page No #{page_no}"
        page_records = save_response(page_no)
        break if page_records.empty? || page_records.count < 19
        page_no = page_no + 1
      rescue Exception => e
        puts e.full_message
        Hamster.report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nDownload error:\n#{e.full_message}", use: :slack)
      end
    end
  end

  def scrape
    begin
      process_file
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def process_file
    files_list = peon.give_list(subfolder: "#{SUB_FOLDER}_#{@run_id.run_id}")
    files_list.each do |file|
      data_array = []
      file_content = peon.give(subfolder: "#{SUB_FOLDER}_#{@run_id.run_id}", file: file)
      data_array = @parser_obj.parse(file_content)
      data_array = aws_processing(data_array)
      data_array.map!{|e| e.merge!({run_id: @run_id.run_id})}
      FederalRegisterForecastedNotices.insert_all(data_array) unless data_array.empty?
      puts "Inserted #{data_array.count} "
    end
    @run_id.finish
  end

  def save_response(page_no)
    new_record_urls = []
    response, code = connect_to(JSON_URL + "&page=#{page_no}")
    file_data = response.body
    data = JSON.parse(file_data)
    results = data["results"]
    results = [] if results.nil?
    results.each_with_index do |result, ind|
      html_url = result["html_url"].strip rescue nil
      next if @already_inserted_links.include? html_url
      new_record_urls << html_url
    end

    if new_record_urls.count > 0
      save_file(file_data, page_no)
    end
    new_record_urls
  end

  def save_file(data, page_no)
    peon.put content: data, file: "#{@run_id.run_id}_#{FILE_NAME}_#{page_no}", subfolder: "#{SUB_FOLDER}_#{@run_id.run_id}"
  end

  def aws_processing(data_array)
    data_array_updated = [] 
    data_array.each do |data|
      pdf_url = data[:pdf_link]
      puts "processing pdf link #{pdf_url}"
      pdf_name = download_file(pdf_url)
      aws_url = upload(pdf_url, pdf_name)
      data[:aws_pdf_link] = aws_url
      data_array_updated.append(data)
    end
    data_array_updated
  end

  def download_file(pdf_url)
    pdf_name = Digest::MD5.hexdigest pdf_url
    response, code = connect_to(pdf_url)
    peon.put content: response&.body, file: pdf_name + ".pdf", subfolder: "PDF"
    puts "Pdf file downloaded..!"
    pdf_name
  end

  def upload(pdf_url, pdf_name)
    content = peon.give(file: "#{pdf_name}.pdf.gz", subfolder: "PDF")
    key = "FederalRegister-ForecastedNotices_#{pdf_url.split("/").last}"
    return @s3.put_file(content, key, metadata={url: pdf_url})
  end

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
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

  def run
    RunId.new(FederalRegisterForecastedNoticesRun)
  end

end
