require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require 'pry'

class Manager < Hamster::Scraper

  SUB_FOLDER = 'inspectorReports'
  BASE_URL = "https://www.oversight.gov"

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @dir_path = @_storehouse_ + 'filename_link.csv'
    @s3 = AwsS3.new(bucket_key = :loki, account=:loki)
    @files_to_link = {}
    if File.file?(@dir_path)
      table = CSV.parse(File.read(@dir_path), headers: false)
      table.map{ |x| @files_to_link[x[0]] = x[1] }
    end
  end

  def download
    ['reports', 'investigations'].each do |keyword|
      url = BASE_URL + "/#{keyword}?page=0&items_per_page=60"
      response, status = @scraper.get_request(url)
      total_page_count = (@parser.get_total_pages(response.body).to_i/60) + 1
      (0..total_page_count).each do |page_number|
        download_page(keyword, page_number)
      end
    end
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  def daily_download
    # data is huge in case of reports so will be daily checking first 10 pages to get any new information.
    ['reports', 'investigations'].each do |keyword|
      (0..10).each do |page_number|
        download_page(keyword, page_number)
      end
    end
  end

  def daily_store
    begin
      process_daily_files
    rescue Exception => e
      puts e.full_message
      Hamster.report(to: 'Abdur Rehman', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nScrape error:\n#{e.full_message}", use: :slack)
    end
  end

  private

  def download_page(keyword, page_number)
    url = BASE_URL + "/#{keyword}?page=#{page_number}&items_per_page=60"
    response, status = @scraper.get_request(url)
    rows = @parser.get_table_rows(response.body)
    all_files = peon.give_list(subfolder: SUB_FOLDER)

    rows.each do |row|
      relative_uri = @parser.get_url_from_row(row)
      file_name = Digest::MD5.hexdigest(relative_uri)
      if all_files.include?(file_name + '.gz')
        p "Skipped #{BASE_URL+relative_uri}"
        next
      end
      inner_response ,status = @scraper.get_request(BASE_URL + relative_uri)
      next if status != 200
      save_file(inner_response,file_name)

      @hash = @parser.parse_all_reports(@parser.get_all_reports(inner_response.body))
      
      if @hash.include?("additional_details_link")
        link_response, status = @scraper.get_request(@hash['additional_details_link'])
        if @hash['additional_details_link'].include?(".pdf")
          file_name = Digest::MD5.hexdigest(@hash['additional_details_link']) + '.pdf'
          save_pdf(link_response&.body, file_name) if status == 200
          save_csv(file_name, @hash['additional_details_link']) if status == 200
        else
          file_name = Digest::MD5.hexdigest(@hash['additional_details_link'])
          save_file(link_response,file_name) if status == 200
          save_csv(file_name, @hash['additional_details_link']) if status == 200
        end
      end
    
      if @hash.include?("report_pdf_link")
        file_name = Digest::MD5.hexdigest(@hash['report_pdf_link']) + '.pdf'
        pdf_response ,status = @scraper.get_request(@hash['report_pdf_link'])
        save_pdf(pdf_response&.body, file_name) if status == 200
        save_csv(file_name, @hash['report_pdf_link']) if status == 200
      end
    end
    
    save_file(response,"#{keyword}_page_#{page_number}")
  end

  def process_daily_files
    ['reports', 'investigations'].each do |keyword|
      (0..10).each do |page_number|
        file_name = "#{keyword}_page_#{page_number}.gz"
        process_file(file_name)
      end
    end
    @keeper.finish
  end

  def process_each_file
    @all_files = peon.give_list(subfolder: SUB_FOLDER)
    @all_files = @all_files.select{|x| x.include?("page")}
    @all_files.each do |file_name|
      puts "Parsing file #{file_name}".yellow
      process_file(file_name)
    end
    @keeper.finish
  end

  def process_file(file_name)
    file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
    rows = @parser.get_table_rows(file_content)

    rows.each do |row|
      relative_uri = @parser.get_url_from_row(row)
      file_name = Digest::MD5.hexdigest(relative_uri)

      puts "Processing Inner link #{relative_uri}".blue
      inner_file_content = peon.give(subfolder: SUB_FOLDER, file: file_name)
      all_reports = @parser.get_all_reports(inner_file_content)
      @hash = @parser.parse_all_reports(all_reports)

      @hash['title'] = @parser.get_title_from_page(inner_file_content)

      @locations = @parser.parse_location(@hash['Location'])
      @hash['data_source_url'] = BASE_URL + relative_uri
      @hash.delete('Location')

      aws_pdf_link = put_pdf_in_aws(@hash['report_pdf_link'])
      @hash['aws_report_pdf'] = aws_pdf_link

      if @hash['additional_details_link']&.include?(".pdf")
        additional_details_on_aws = put_pdf_in_aws(@hash['additional_details_link'])
      else
        additional_details_on_aws = put_html_in_aws(@hash['additional_details_link'])
      end
      @hash['aws_additional_details'] = additional_details_on_aws

      @keeper.store_reports(@hash)

      @locations.each do |location|
        location['report_id'] = @keeper.get_report_id(@hash['data_source_url'])
        @keeper.store_report_locations(location)
      end
    end
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: SUB_FOLDER
  end

  def save_pdf(pdf , file_name)
    pdf_storage_path = @_storehouse_ + "store/#{file_name}"
    unless @files_to_link[file_name].present?
      File.open(pdf_storage_path, "wb") do |f|
        f.write(pdf)
      end
    end
  end

  def put_pdf_in_aws(link)
    return unless link.present?
    md5_hash = Digest::MD5.hexdigest(link) + '.pdf'
    pdf_storage_path = @_storehouse_ + "store/#{md5_hash}"
    key = md5_hash
    aws_link = nil
    if @s3.find_files_in_s3(key).empty?
      if File.file?(pdf_storage_path)
        aws_link = @s3.put_file(File.open(pdf_storage_path), key , metadata={ url: link})
      end
    else
      aws_link = 'https://loki-files.s3.amazonaws.com/' + key
    end
    aws_link
  end

  def put_html_in_aws(link)
    return unless link.present?
    md5_hash = Digest::MD5.hexdigest(link)
    key = md5_hash + '.html'
    aws_link = nil
    if @s3.find_files_in_s3(key).empty?
      if @files_to_link[md5_hash].present?
        file_content = peon.give(subfolder: SUB_FOLDER, file: md5_hash)
        aws_link = @s3.put_file(file_content, key , metadata={ url: link})
      end
    else
      aws_link = 'https://loki-files.s3.amazonaws.com/' + key
    end
    aws_link
  end

  def save_csv(file_name,link)
    rows = [[file_name , link]]
    File.open(@dir_path, 'a') { |file| file.write(rows.map(&:to_csv).join) }
  end

end
