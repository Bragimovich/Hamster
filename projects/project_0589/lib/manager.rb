# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @s3 = AwsS3.new(bucket_key = :us_court)
  end


  
  def download
    store if (keeper.download_status == "finish")
    scraper = Scraper.new
    years = (2016..Date.today.year).map(&:to_i)
    years.each do |year|
      main_page = scraper.connect_to("https://www.la2nd.org/opinions/?opinion_year=#{year}")
      save_page(main_page,"#{year}_main_page","#{keeper.run_id}/")
      page = parser.parse_page(main_page.body)
      pdf_links = parser.get_pdf_links(page)
      pdf_links.each do |link|
        file_name = Digest::MD5.hexdigest link
        pdf_response = scraper.connect_to(link)
        save_pdf(pdf_response.body, file_name, year)
        save_page(pdf_response,file_name,"#{keeper.run_id}/pdfs/#{year}/")
      end
    end
    keeper.finish_download
    store if (keeper.download_status == "finish")
  end

  def store
    outer_pages = peon.give_list(subfolder: "#{keeper.run_id}")
    outer_pages.each do |outer_page|
      info_md5_array = []
      add_info_md5_array = []
      processed_files = file_handling(processed_files,'r') rescue []
      year = "#{outer_page.split('_').first}"
      pdf_paths = Dir["#{storehouse}/store/#{keeper.run_id}/pdfs/#{year}/*.pdf"]
      outer_page_body = peon.give(subfolder: "#{keeper.run_id}", file: outer_page)
      page = parser.parse_page(outer_page_body)
      pdf_links = parser.get_pdf_links(page)
      pdf_links.each do |pdf_link|
        file_name = Digest::MD5.hexdigest pdf_link
        logger.debug("Processing year => #{year} => Pdf file => #{file_name}")
        next if (processed_files.include? file_name)
        pdf_file = peon.give(subfolder: "#{keeper.run_id}/pdfs/#{year}", file: file_name) rescue nil
        next if pdf_file.nil?
        pdf_path = pdf_paths.select{|file| file.include? file_name}.first
        parser.initialize_values(pdf_path,keeper.run_id)
        case_info,opinion_date = parser.parse_case_info(page,pdf_link,year)
        info_md5_array = info_md5_array + case_info.map { |e| e[:md5_hash] }
        add_info = parser.parse_additional_info(year)
        add_info_md5_array = add_info_md5_array + add_info.map { |e| e[:md5_hash] }
        activity_info,activity_md5 = parser.parse_activities(pdf_link,opinion_date,year)
        aws_info,aws_md5 = parser.parse_case_pdf_aws(pdf_link)
        activity_relation = parser.parse_relation_activity(activity_md5,aws_md5)
        party_info = parser.parse_parties(year,pdf_link)
        aws_info = upload_file_to_aws(pdf_file,aws_info) unless aws_info.empty?
        keeper.insert_records(party_info,'party') rescue next
        keeper.insert_records(case_info,'info')
        keeper.insert_records(add_info,'add_info')
        keeper.insert_records(activity_info,'activity')
        keeper.insert_records(aws_info,'aws')
        keeper.insert_records(activity_relation,'relation')
        file_handling(file_name,'a')
      end
      info_md5_array.each_slice(2000){|data| keeper.update_touch_run_id(data, 'info')}
      add_info_md5_array.each_slice(2000){|data| keeper.update_touch_run_id(data, 'add_info')}
    end
    File.delete("#{storehouse}store/#{keeper.run_id}/links.txt")
    if (keeper.download_status == "finish")
      keeper.mark_delete('info')
      keeper.mark_delete('add_info')
      keeper.finish
    end
  end

  private

  attr_accessor :keeper, :parser

  def upload_file_to_aws(html,aws_array)
    aws_array.each{|e| e[:aws_link] = @s3.put_file(html,e[:aws_link],metadata={})}
  end

  def save_pdf(content, file_name,year)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}/pdfs/#{year}"
    pdf_storage_path = "#{storehouse}store/#{keeper.run_id}/pdfs/#{year}/#{file_name}.pdf"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def file_handling(content,flag)
    list = []
    File.open("#{storehouse}store/#{keeper.run_id}/links.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

end
