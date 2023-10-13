# frozen_string_literal: true
require_relative '../models/ga_ac_case_activities'
require_relative '../models/ga_ac_case_additional_info'
require_relative '../models/ga_ac_case_info'
require_relative '../models/ga_ac_case_party'
require_relative '../models/ga_ac_case_pdfs_on_aws'
require_relative '../models/ga_ac_case_relations'
require_relative '../models/ga_ac_case_run'
require_relative '../lib/parser'

class Scraper <  Hamster::Scraper

  def initialize
    super  
    @parser_obj = Parser.new
    @already_inserted_links = GaAcCaseInfo.where(status_as_of_date: 'Final').pluck(:data_source_url)
    @links = GaAcCaseInfo.where(deleted: 0).where.not(status_as_of_date: 'Final').pluck(:data_source_url)
    @s3 = AwsS3.new(bucket_key = :us_court)
    @run_object = RunId.new(GaAcCaseRun)
    @subfolder = "Run_Id_#{@run_object.run_id}" 
  end

  def download
    outer_page = connect_to(url: prepare_url)
    save_file(outer_page, "outer_page")
    links = @parser_obj.get_inner_links(outer_page.body)
    process_inner_pages(links)
  end

  def store
    error_count = 0
    outer_page = peon.give(subfolder:@subfolder , file:"outer_page.gz") 
    links = @parser_obj.get_inner_links(outer_page) 
    downloaded_files = peon.give_list(subfolder: @subfolder)
    already_processed_links = GaAcCaseInfo.where(run_id: @run_object.last_id).pluck(:data_source_url)
    links.concat(@links)
    links.each do |link|
      begin
        file_md5 = Digest::MD5.hexdigest link
        file_name = file_md5 + '.gz'
        next unless downloaded_files.include? file_name
        next if already_processed_links.include? link
        file_content = peon.give(subfolder: @subfolder, file: file_name)
        info_data, add_info_data, party_data, activity_data, aws_data, activity_pdf_data = @parser_obj.parse(file_content, link, @run_object.last_id)
        aws_data[:aws_link] = upload_file_to_aws(aws_data) unless aws_data.empty?
        GaAcCaseInfo.insert(info_data) unless info_data.empty?
        GaAcCaseAdditionalInfo.insert(add_info_data) unless add_info_data.empty?
        GaAcCaseParty.insert_all(party_data) unless party_data.empty?
        GaAcCaseActivities.insert_all(activity_data) unless activity_data.empty?
        GaAcCasePdfsOnAws.insert(aws_data) unless aws_data.empty?
        GaAcCaseRelationsInfoPdf.insert(activity_pdf_data) unless aws_data.empty?
      rescue Exception => e
        error_count += 1
        if error_count > 10
          Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
        end
      end
    end
    mark_delete('info')
    mark_delete('aws')
    mark_delete_relation
    @run_object.finish
  end

  private

  def prepare_url
    start_date = GaAcCaseInfo.pluck(:disposition_or_status).reject{|e| e.nil?}.map{|e| e.split("(").last.split(")").first}.max.to_date.strftime("%Y-%m-%d")
    current_date = Date.today.strftime("%Y-%m-%d")
    "https://www.gaappeals.us/wp-content/themes/benjamin/docket/docketdate/results_all.php?OPstartDate=#{start_date}&OPendDate=#{current_date}&submit=Start+Opinions+Search"
  end

  def process_inner_pages(links)
    downloaded_files = peon.give_list(subfolder: @subfolder)
    links.concat(@links)
    links.each do |link|
      file_name = Digest::MD5.hexdigest link
      next if @already_inserted_links.include? link
      next if downloaded_files.include? file_name + ".gz"
      page, code = connect_to(link)
      next if page.nil?
      save_file(page,file_name)
    end
  end

  def mark_delete_relation
    info_array = GaAcCaseInfo.where(deleted: 1).pluck(:md5_hash)
    GaAcCaseRelationsInfoPdf.where(:case_info_md5 => info_array).update_all(:deleted => 1)
  end

  def mark_delete(value)
    model = value == 'info' ? GaAcCaseInfo : GaAcCasePdfsOnAws
    ids_extract = model.where(:deleted => 0).group(:case_id).having("count(*) > 1").pluck("case_id, GROUP_CONCAT(id)")
    all_old_ids = []
    ids_extract.each do |value|
      ids = value[-1].split(",").map(&:to_i)
      ids.delete ids.max
      all_old_ids << ids
    end
    all_old_ids = all_old_ids.flatten
    model.where(:id => all_old_ids).update_all(:deleted => 1)
  end

  def save_file(html, file_name)
    peon.put content: html.body, file: "#{file_name}", subfolder: @subfolder
  end  

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

  def upload_file_to_aws(aws_atemp)
    aws_url = "https://court-cases-activities.s3.amazonaws.com/"
    return aws_url + aws_atemp[:aws_link] unless @s3.find_files_in_s3(aws_atemp[:aws_link]).empty?
    key = aws_atemp[:aws_link]
    pdf_url = aws_atemp[:source_link]
    if pdf_url== nil || pdf_url=="https://efast.gaappeals.us/download?filingId="
      return nil
    end
    response, code = connect_to(pdf_url)
    content = response&.body
    @s3.put_file(content, key, metadata={})
  end
end
