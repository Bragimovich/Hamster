# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @s3 = AwsS3.new(bucket_key = :us_court)
  end

  def run
    (keeper.download_status(keeper.run_id)[0].to_s == "true") ? store : download
  end

  def download
    scraper = Scraper.new
    already_inserted_date, already_inserted_pdf = already_downloaded_files
    main_page = scraper.main_page
    headers   = {"Cookie": main_page.headers['set-cookie']}
    main_page = parser.parse_html(main_page.body)
    request_Token = parser.get_request_verificatio_token(main_page)
    allDates = get_dates
    allDates.each do |date_range|
      startDate = date_range.first.strftime("%Y-%m-%d")
      endDate   = date_range.last.strftime("%Y-%m-%d")
      next if already_inserted_date.gsub("_","-").to_date > startDate.to_date unless already_inserted_date.empty?

      main_page          = scraper.get_page_request(headers, startDate, endDate, request_Token[0])
      save_file(main_page, "source", "#{keeper.run_id}/#{startDate.gsub("-","_")}")
      main_page          = parser.parse_html(main_page.body)
      pdf_links, row_data    = parser.pdf_links(main_page)
      pdf_links.each_with_index do |pdf_link, index|
        pdf_url = "https://ujsportal.pacourts.us#{pdf_link}"
        file_name = Digest::MD5.hexdigest pdf_url
        next if already_inserted_pdf.include? "#{file_name}.pdf"

        pdf_response = scraper.main_page(pdf_url)
        save_pdf(pdf_response.body, file_name, startDate.gsub("-","_"))
        save_file(pdf_response, file_name, "#{keeper.run_id}/#{startDate.gsub("-","_")}")
      end
    end
    keeper.mark_download_status(keeper.run_id)
  end

  def store
    year_folders = peon.list(subfolder: "#{keeper.run_id}").sort
    year_folders.each do |year_folder|
      main_page = peon.give(subfolder: "#{keeper.run_id}/#{year_folder}", file: "source")
      main_page = parser.parse_html(main_page)
      info_del = []
      activity_del = []
      judgement_del = []
      party_del = []
      pdf_files, row_data =  parser.pdf_links(main_page)
      pdf_files.each_with_index do |pdf_file, index|
        url = "https://ujsportal.pacourts.us#{pdf_file}"
        file_name = Digest::MD5.hexdigest url
        file = parser.pdf_parsing("#{storehouse}store/#{keeper.run_id}/#{year_folder}/#{file_name}.pdf") rescue nil
        next if file.nil?

        page = peon.give(file: file_name, subfolder: "#{keeper.run_id}/#{year_folder}") rescue nil
        next if page.nil?

        info_data, judgement = (parser.case_data(file, keeper.run_id, url, row_data[index]))
        info_del << info_data[:md5_hash]
        keeper.insert_case("CaseInfo", [info_data])
        unless ((judgement.nil?) || (judgement.empty?))
          keeper.insert_case("CaseJudgement", [judgement])
          judgement_del << judgement[:mdf_hash]
        end
        aws_data = parser.get_aws_uploads(page, keeper.run_id, url, row_data[index], s3)
        keeper.insert_case("CasePdfsOnAWS", [aws_data])
        keeper.insert_case("CaseRelationsInfo", [parser.get_relations_pdf(info_data[:md5_hash], aws_data[:md5_hash], keeper.run_id)])
        activities, aws_upload = parser.get_activities(file, keeper.run_id, url, aws_data)
        unless ((activities.nil?) || (activities.empty?))
          keeper.insert_case("CaseActivities", activities)
          keeper.insert_case("CaseRelationsActivity", [aws_upload])
          activity_del << activities.map { |e| e[:md5_hash] }
        end
        party_array = parser.get_lawyer(file, keeper.run_id, url, file_name)
        keeper.insert_case("CaseParty", party_array)
        party_del << party_array.map { |e| e[:md5_hash] }
      end
      update_touched_run_id(info_del, activity_del, judgement_del, party_del)
    end
    mark_deleted
    keeper.finish
  end

  private

  attr_accessor :parser, :keeper, :s3, :closed_records

  def mark_deleted
    keeper.mark_deleted("CaseInfo")
    keeper.mark_deleted("CaseActivities")
    keeper.mark_deleted("CaseJudgement")
    keeper.mark_deleted("CaseParty")
  end

  def update_touched_run_id(info_del, activity_del, judgement_del, party_del)
    keeper.update_touched_run_id(info_del.flatten, "CaseInfo")
    keeper.update_touched_run_id(activity_del.flatten, "CaseActivities")
    keeper.update_touched_run_id(judgement_del.flatten, "CaseJudgement")
    keeper.update_touched_run_id(party_del.flatten, "CaseParty")
  end

  def get_dates
    ((Date.parse("01/01/2016"))..(Date.today-1)).map(&:to_date).each_slice(180)
  end

  def save_pdf(content, file_name, folder_name)
    content = "#{content.split('%%EOF').first}%%EOF"
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}/#{folder_name}"
    pdf_storage_path = "#{storehouse}store/#{keeper.run_id}/#{folder_name}/#{file_name}.pdf"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html.body, file: file_name, subfolder: subfolder
  end

  def already_downloaded_files
    folders = peon.list(subfolder: "#{keeper.run_id}").sort.last rescue []
    pages = peon.list(subfolder: "#{keeper.run_id}/#{folders}") rescue []
    [folders, pages]
  end
end
