# frozen_string_literal: true
require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
    @subfolder = "Run_Id_#{keeper.run_id}"
    @s3 = AwsS3.new(bucket_key = :us_court)
    @already_inserted_records = keeper.already_inserted_ids
  end

  def run(year)
    (keeper.download_status == "finish") ? store : download(year)
  end

  def download(year)
    all_dates = date_array(year)
    downloaded_files = resume
    downloaded_activities = already_downloaded
    all_dates.each do |date_interval|
      start_date, last_date = date_converter(date_interval)
      res = scraper.logAnonymouse
      requestor_id = parser.get_request_id(parser.json_response(res.body))
      response = scraper.main_request
      main_tab = scraper.search_tab
      response = scraper.search(requestor_id, start_date, last_date)
      sub_directory = create_subdirectory(date_interval)
      save_file(response.body, "outer_page", "#{subfolder}/#{sub_directory}")
      page = parser.json_response(response.body)
      process_results(page["data"], requestor_id, sub_directory, downloaded_files, downloaded_activities)
    end
    keeper.download_status
    keeper.finish_download
    store if (keeper.download_status == "finish")
  end

  def store
    sub_directories_intervals = peon.list(subfolder: subfolder)
    error_count = 1
    sub_directories_intervals.each do |dir_interval|
      keeper.mark_delete(dir_interval)
      md5_hashes_array = []
      begin
        court_dirs_in_interval = peon.list(subfolder: "#{subfolder}/#{dir_interval}")
        court_dirs_in_interval.each do |file_folder|
          next if file_folder.include? ".gz"
          summary_response, event_response, parties_response, pdf_content, pdf_file, activity_pdfs = get_file_response(dir_interval, file_folder)

          info_array, pdfs_on_aws_array, relations_info_pdf_array = parser.get_summary_data(summary_response, pdf_content, pdf_file, @s3, keeper.run_id)
          next if info_array == nil or  @already_inserted_records.include? info_array[:case_id]
          md5_hashes_array << info_array[:md5_hash]
          party_array = parser.get_party_data(parties_response, info_array[:case_id], keeper.run_id)
          path = "#{subfolder}/#{dir_interval}/#{file_folder}"
          activities_array, relations_activity_pdf_array, activity_pdfs_on_aws_array = parser.get_case_activities(event_response, activity_pdfs, @s3, keeper.run_id, "#{path}/activity_pdfs")

          keeper.make_insertion("FlCaseInfo", info_array)
          keeper.make_insertion("FlCasePdfOnAws", pdfs_on_aws_array)
          keeper.make_insertion("FlCasePdfOnAws", activity_pdfs_on_aws_array)
          keeper.make_insertion("FlCaseRelationInfoPdf", relations_info_pdf_array)
          keeper.make_insertion("FlCaseParty", party_array)
          keeper.make_insertion("FlCaseActivities", activities_array)
          keeper.make_insertion("FlCaseRelationActivityPdf", relations_activity_pdf_array)
        end
      rescue StandardError => e
        error_count += 1
        if error_count > 10
          Hamster.report(to: 'U04MKV2QWQ4', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
          return
        end
      end
      keeper.update_touch_run_id(md5_hashes_array)
      keeper.mark_delete(dir_interval)
    end
    keeper.finish if keeper.download_status == "finish"
  end

  private
  attr_accessor :keeper, :parser, :scraper, :subfolder

  def process_results(all_rows, requestor_id, sub_directory, downloaded_files, downloaded_activities)
    all_rows.each do |row|
      case_id = row["caseNumber"]
      next if @already_inserted_records.include? case_id
      case_regex = case_id.scan(/[A-Za-z0-9]/).flatten.join
      next if downloaded_files.include? case_regex

      file_path = create_path(sub_directory,case_regex)
      
      window = scraper.search_window(case_id, requestor_id)
      
      case_response = scraper.case_search(case_id, requestor_id)
      party_response = scraper.party_search(case_id, requestor_id)
      event_response, all_events = get_events(case_id, requestor_id)
      pdf_response = scraper.pdf_search(case_id, requestor_id)

      save_file(case_response.body, "summary", file_path)
      save_file(party_response.body, "parties", file_path)
      save_file(event_response.body, "events", file_path)
      save_file(pdf_response.body, "#{case_regex}_pdf", file_path)
      process_events(all_events, requestor_id, file_path, downloaded_activities)
    end
  end

  def get_events(case_id, requestor_id)
    event_response = scraper.event_search(case_id, requestor_id)
    all_events = parser.json_response(event_response.body)
    (1..10).each do |counter|
      if events_available(all_events)
        event_response = scraper.event_search(case_id, requestor_id)
        all_events = parser.json_response(event_response.body)
      else
        break
      end
    end
    [event_response, all_events]
  end

  def process_events(all_events, requestor_id, file_path, downloaded_activities)
    return if events_available(all_events)
    all_events["data"].each do |event|
      if activity_pdf_check(event)
        file_name = Digest::MD5.hexdigest event.to_s
        next if downloaded_activities.include?(file_name)
        doc_id = event["documentID"]
        doc_ver_id = event["documentVersionID"]
        response = scraper.activity_pdf_request(doc_id, doc_ver_id, requestor_id)
        save_file(response.body, file_name, "#{file_path}/activity_pdfs")
      end
    end
  end

  def events_available(all_events)
    all_events["data"].nil? ? true : false
  end

  def activity_pdf_check(event)
    (!event["documentPath"].empty? and event["documentPath"].include? ".pdf") ? true : false
  end

  def get_file_response(dir_interval, file_folder)
    path = "#{subfolder}/#{dir_interval}/#{file_folder}"
    summary = peon.give(subfolder: path, file: "summary.gz")
    event = peon.give(subfolder: path, file: "events.gz")
    parties = peon.give(subfolder: path, file: "parties.gz")
    pdf_name = peon.list(subfolder: path).select{|file| file.include? "_pdf.gz"}
    pdf_content = peon.give(subfolder: path, file: pdf_name.first)
    activity_pdfs = peon.list(subfolder: "#{path}/activity_pdfs") rescue nil
    [summary, event, parties, pdf_content, pdf_name.first, activity_pdfs]
  end

  def create_path(sub_directory,case_regex)
    "#{subfolder}/#{sub_directory}/#{case_regex}"
  end

  def resume
    files = []
    all_folders = peon.list(subfolder: subfolder) rescue []
    all_folders.each do |folder|
      files << peon.list(subfolder: "#{subfolder}/#{folder}")
    end
    files.flatten.reject{|e| e.include? 'outer_page'}.uniq
  end

  def already_downloaded
    files = []
    all_folders = peon.list(subfolder: subfolder) rescue []
    all_folders.each do |folder|
      inner_folders = peon.list(subfolder: "#{subfolder}/#{folder}")
      inner_folders.each do |activity_folder|
        next if activity_folder == "outer_page.gz"
        check = peon.list(subfolder: "#{subfolder}/#{folder}/#{activity_folder}/activity_pdfs") rescue nil
        next if check == nil
        files << peon.list(subfolder: "#{subfolder}/#{folder}/#{activity_folder}/activity_pdfs")
      end
    end
    files.flatten
  end

  def date_array(year)
    if year == '--download'
      return (keeper.fetch_max_date..(Date.today)).map(&:to_date).reverse.each_slice(10)
    elsif year.to_i == Date.today.year
      return (Date.parse("01/01/#{Date.today.year}")..(Date.today)).map(&:to_date).reverse.each_slice(10)
    else
      return (Date.parse("01/01/#{year}")..(Date.parse("31/12/#{year}"))).map(&:to_date).reverse.each_slice(10)
    end
  end

  def create_subdirectory(date_interval)
    "#{date_interval.first.to_s.gsub('-','_')}_to_#{date_interval.last.to_s.gsub('-','_')}"
  end

  def date_converter(date_interval)
    start_date = date_interval.last
    last_date = date_interval.first
    ["#{get_month(start_date)}/#{get_day(start_date)}/#{start_date.year}", "#{get_month(last_date)}/#{get_day(last_date)}/#{last_date.year}"]
  end

  def get_day(date_val)
    date_val.day.to_s.size == 1 ? "0#{date_val.day}" : date_val.day
  end

  def get_month(date_val)
    date_val.month.to_s.size == 1 ? "0#{date_val.month}" : date_val.month
  end

  def save_file(body, file_name, sub_folder)
    begin
      peon.put(content: body, file: file_name, subfolder: sub_folder)
    rescue StandardError => e
      Hamster.logger.error(e)
    end
  end
end
