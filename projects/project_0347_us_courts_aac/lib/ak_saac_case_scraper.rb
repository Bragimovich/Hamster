# frozen_string_literal: true

require_relative '../models/ak_saac_case_runs'
require_relative '../models/ak_saac_case_info'
require_relative '../models/ak_saac_case_pdfs_on_aws'

class AkSaacCaseScraper < Hamster::Scraper

  SOURCE = 'https://appellate-records.courts.alaska.gov'
  SUPREME_COURT = {
    id: 302,
    search_range: ('s16'..'s18'),
    index_folder: 'sc_indexes/',
    cases_folder: 'sc_cases/'
  }
  APPELLATE_COURT = {
    id: 403,
    search_range: ('a12'..'a14'),
    index_folder: 'ac_indexes/',
    cases_folder: 'ac_cases/'
  }

  def initialize(*_)
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @year = 2016
    @court = nil
    @run_id = nil
    @update = nil
  end

  def start(update: false)
    send_to_slack("Project #0347 download started")
    log_download_started

    tar_store_to_trash
    @update = update
    download

    log_download_finished
    send_to_slack("Project #0347 download finished")
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in start:\n#{e.inspect}")
  end

  private

  def download
    @court = SUPREME_COURT
    save_index_pages

    @court = APPELLATE_COURT
    save_index_pages
  end

  def save_index_pages
    rejected_cases = collect_ignored_cases
    @court[:search_range].each do |s|
      p "#{"=" * 50} #{s} #{"=" * 50}"
      page_link = SOURCE + "/CMSPublic/Search/CaseNumber?CaseNumber=#{s}&TrialCourtNumber="
      index_page = load_web_resource(page_link)&.body

      save_file(index_page, s, @court[:index_folder])
      save_index_cases(index_page, rejected_cases)
    end
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in save_index_pages:\n#{e.inspect}")
  end

  def save_index_cases(index_page, rejected_cases)
    rows = Nokogiri::HTML(index_page).css('.cms-table-results tbody tr')
    rows.each do |row|
      case_id = row.at('a')&.text&.strip
      next if case_id.nil?
      next if (case_filed_year(row) < @year)
      next if rejected_cases.include? case_id
      case_link = parse_case_link(row)
      save_case(case_link, case_id)
    rescue StandardError => e
      print_all case_id, e, e.full_message, title: " ERROR "
      send_to_slack("project_0347 error in save_cases #{case_id}:\n#{e.inspect}")
    end
  end

  def parse_case_link(row)
    SOURCE + row.at('a')&.attr('href')
  end

  def save_case(case_link, case_id)
    #save info file
    case_info = load_web_resource(case_link)&.body
    info_file_name = "#{case_id}_info"
    save_file(case_info, info_file_name, @court[:cases_folder])

    #save parties file
    party_link = case_link.sub("General", "Parties")
    case_parties = load_web_resource(party_link)&.body
    party_file_name = "#{case_id}_party"
    save_file(case_parties, party_file_name, @court[:cases_folder])

    #save activities file
    docket_link = case_link.sub("General", "Docket")
    case_docket = load_web_resource(docket_link)&.body
    docket_file_name = "#{case_id}_docket"
    save_file(case_docket, docket_file_name, @court[:cases_folder])
    save_pdfs(docket_link, case_docket, case_id)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in save_case - #{case_id}:\n#{e.inspect}")
  end

  def save_pdfs(link, page, case_id)
    activities = Nokogiri::HTML(page).css('.cms-docket-table tbody tr')
    key_start = "us_courts_expansion_#{@court[:id]}_#{case_id}_"
    aws_keys = %i[court_id case_id source_type aws_link source_link data_source_url]
    case_pdfs = collect_case_pdfs(case_id)
    case_pdfs_to_update = []
    case_pdfs_to_save = []

    activities.each do |activity|
      path_to_pdf = activity.css('td')[1].at('a')&.attr('href') #docket.at('td a')&.attr('href')
      next if path_to_pdf.nil?
      pdf_url = SOURCE + path_to_pdf
      if case_pdfs.include? pdf_url
        case_pdfs_to_update.push(pdf_url)
        next
      end
      pdf_aws_url = save_to_aws(pdf_url, key_start)
      next if path_to_pdf.nil?
      aac_case_pdfs_on_aws = {
        court_id: @court[:id],
        case_id: case_id,
        source_type: 'activity',
        aws_link: pdf_aws_url,
        source_link: pdf_url,
        data_source_url: link
      }
      aac_case_pdfs_on_aws[:md5_hash] = calc_md5_hash(aac_case_pdfs_on_aws)
      aac_case_pdfs_on_aws[:run_id] = @run_id
      aac_case_pdfs_on_aws[:touched_run_id] = @run_id
      case_pdfs_to_save.push(aac_case_pdfs_on_aws)
    end

    AkSaacCasePdfsOnAWS.insert_all(case_pdfs_to_save) unless case_pdfs_to_save.empty?
    AkSaacCasePdfsOnAWS.where(source_link: case_pdfs_to_update).update_all(touched_run_id: @run_id)
    AkSaacCasePdfsOnAWS.where(case_id: case_id, deleted: 0).where.not(touched_run_id: @run_id).update_all "deleted = 1"
  end

  def case_filed_year(case_item)
    case_link = SOURCE + case_item.css('a').first['href']
    if case_item.css('td')[5].nil? || case_item.css('td')[5].text.strip.to_date.nil?
      page = load_web_resource(case_link)&.body
      info = Nokogiri::HTML(page)
      year = Date.strptime(info.css('.col-sm-5 dd')[1].text.strip, '%m/%d/%Y').year
    else
      year = case_item.css('td')[5].text.strip.to_date.year
    end
    year
  end

  def collect_ignored_cases
    if @update
      collect_stored_cases(@court[:id])
    else
      collect_closed_cases(@court[:id])
    end
  end

  def collect_stored_cases(court_id)
    AkSaacCaseInfo.where(deleted: 0, court_id: court_id).pluck(:case_id).to_set
  end

  def collect_closed_cases(court_id)
    AkSaacCaseInfo.where(deleted: 0, court_id: court_id, status_as_of_date: 'Closed').pluck(:case_id).to_set
  end

  def collect_case_pdfs(case_id)
    AkSaacCasePdfsOnAWS.where(court_id: @court[:id], case_id: case_id).pluck(:source_link).to_set
  end

  def save_to_aws(url_file, key_start)
    response = load_web_resource(url_file)
    body = response&.body
    file_name = response&.headers['content-disposition']&.split('=')&.last
    file_name = (Time.now.to_i.to_s + '.pdf') if file_name.blank?
    key = key_start + file_name
    @s3.put_file(body, key, metadata = { url: url_file })
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack "project_0347 error in save_to_aws:\n#{url_file}\n#{e.inspect}"
    nil
  end

  def tar_store_to_trash
    prev_run_id = @run_id.to_i - 1
    run_name_justified = prev_run_id.to_s.rjust(4, "0")
    tar_file = "#{run_name_justified}.tar"
    src_dir = "#{@_storehouse_}store/"
    dest_dir = "#{@_storehouse_}trash/"
    Minitar.pack(src_dir, File.open("#{dest_dir}#{tar_file}", 'wb'))
    FileUtils.rm_r Dir.glob("#{src_dir}*")
  end

  def save_file(html, name, folder)
    peon.put content: html, file: name, subfolder: folder
  end

  def calc_md5_hash(hash)
    Digest::MD5.hexdigest hash.values.join
  end

  def log_download_started
    @run_id = AkSaacCaseRuns.create(status: 'download started').id
    puts "#{"="*50} download started #{"="*50}"
  end

  def log_download_finished
    AkSaacCaseRuns.find(@run_id).update(status: 'download finished')
    puts "#{"="*50} download finished #{"="*50}"
  end

  def send_to_slack(message)
    Hamster.report(to: 'U031HSK8TGF', message: message)
  end

  def print_all(*args, title: nil, line_feed: true)
    puts "#{"=" * 50}#{title}#{"=" * 50}" if title
    puts args
    puts if line_feed
  end

  def load_web_resource(url)
    attempts ||= 1
    connect_to(url, proxy_filter: @filter, ssl_verify: false)
  rescue StandardError => e
    puts e
    if (attempts += 1) <= 3
      sleep 8**attempts
      puts "<Attempt #{attempts}: retrying ...>"
      retry
    end
    puts "Retry attempts exceeded."
    send_to_slack("project_0347 error in load_web_resource:\n#{e.inspect}")
    raise
  end

end
