# frozen_string_literal: true

require_relative '../models/ks_ac_case_runs'
require_relative '../models/ks_ac_case_info'

class KsAcCaseScraper < Hamster::Scraper

  SOURCE = 'https://pittsreporting.kscourts.org'
  COURT_ID = 430
  YEAR = 2016

  def initialize(*_)
    super
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @run_id = nil
    @cases_folder = nil
    @stored_cases = Set.new
    @no_party_cases = []
  end

  def start(update: false)
    send_to_slack message: "project_0390 - download started"
    log_download_started

    # clear_store_folder
    tar_store_to_trash
    @stored_cases = collect_stored_cases if update
    download

    puts @no_party_cases
    log_download_finished
    send_to_slack message: "project_0390 - download finished"
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack message: "project_0390 start:\n#{e.inspect}"
  end

  private

  def download
    #### save index
    index_page_url = SOURCE + "/Appellate"
    page = post_request(index_page_url)
    index_filename = "#{@run_id.to_s.rjust(4, "0")}_index"
    save_file(page, index_filename)
    #### save cases from index
    save_cases(page)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack message: "project_0390 download:\n#{e.inspect}"
  end

  def save_cases(page)
    @cases_folder = "#{@run_id.to_s.rjust(4, "0")}_cases"
    rows = Nokogiri::HTML(page).at('.body-content table').css('tr')
    rows.each do |row|
      case_id = row.at('a')&.text&.strip
      next if case_id.nil?
      next if (date_docketed(row) < YEAR)
      next if @stored_cases.include?(case_id)
      case_url = SOURCE + row.at('a')&.attr('href')
      save_case(case_url, case_id)
    rescue StandardError => e
      print_all e, e.full_message, title: " ERROR "
      send_to_slack message: "project_0390 save_cases: #{case_id}:\n#{e.inspect}"
    end
  end

  def save_case(case_url, case_id)
    save_info_n_activities(case_url, case_id)
    save_parties(case_url, case_id)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack message: "project_0390 save_case: #{case_id}:\n#{e.inspect}"
  end

  def save_info_n_activities(case_url, case_id)
    case_info = connect_to(case_url, proxy_filter: @filter, ssl_verify: false)&.body
    info_file_name = "#{case_id}_info_n_activities"
    save_file(case_info, info_file_name, @cases_folder)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack message: "project_0390 save_info_n_activities: #{case_id}:\n#{e.inspect}"
  end

  def save_parties(case_url, case_id)
    parties_url = case_url.sub("CaseDetails", "CaseLitigants")
    case_parties = connect_to(parties_url, proxy_filter: @filter, ssl_verify: false)&.body
    parties_file_name = "#{case_id}_parties"
    save_file(case_parties, parties_file_name, @cases_folder)
    rows = Nokogiri::HTML(case_parties).at('.body-content table')&.css('tr')
    return if rows.nil? && @no_party_cases.push(case_id)
    rows.each do |row|
      party_name = row.at('a')&.text&.strip
      next if party_name.nil?
      save_party(case_id, row)
    end
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack message: "project_0390 save_parties: #{case_id}:\n#{e.inspect}"
  end

  def save_party(case_id, row)
    party_link = SOURCE + row.at('a')&.attr('href')
    case_party = connect_to(party_link, proxy_filter: @filter, ssl_verify: false)&.body
    litigantID = party_link.match(/(litigantID=)(\d+)(&)/)[2]
    case_party_name = "#{case_id}_party_#{litigantID}"
    case_party_folder = "#{@cases_folder}/#{case_id}"
    save_file(case_party, case_party_name, case_party_folder)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack message: "project_0390 save_party: #{case_id}:\n#{e.inspect}"
  end

  def post_request(link)
    response = connect_to(link, proxy_filter: @filter, ssl_verify: false)
    page = response&.body
    post_cookie = Nokogiri::HTML(page).at('form input')['value']
    form_data = "__RequestVerificationToken=#{post_cookie}&CaseNumber=&CaseName=%25&County="
    headers = { Content_Type: 'application/x-www-form-urlencoded',
                Cookie: response&.headers['set-cookie'] }
    page_link = SOURCE + '/Appellate/CaseSearch'
    index = connect_to(page_link,
                       proxy_filter: @filter,
                       ssl_verify: false,
                       method: :post,
                       req_body: form_data,
                       headers: headers,)&.body
    index
  end

  def date_docketed(item)
    Date.strptime(item.css('td')[1], '%d-%b-%y').year
  end

  def collect_stored_cases
    KsAcCaseInfo.where(deleted: 0).pluck(:case_id).to_set
  end

  def save_file(html, name, folder=nil)
    peon.put content: html, file: name, subfolder: folder
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

  def clear_store_folder
    date_folder = Time.now.strftime("%Y_%m")
    run_folder = (@run_id - 1).to_s.rjust(4, "0")
    trash_folder = "#{date_folder}/#{run_folder}"
    peon.move_all_to_trash(trash_folder)
  end

  def connect_to(*arguments, &block)
    response = nil
    3.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end
    response
  end

  def log_download_started
    @run_id = KsAcCaseRuns.create(status: 'download started').id
    puts "#{"="*50} download started #{"="*50}"
  end

  def log_download_finished
    KsAcCaseRuns.find(@run_id).update(status: 'download finished')
    puts "#{"="*50} download finished #{"="*50}"
  end

  def print_all(*args, title: nil, line_feed: true)
    puts "#{"=" * 50}#{title}#{"=" * 50}" if title
    puts args
    puts if line_feed
  end

  def send_to_slack(message:, channel: 'U031HSK8TGF')
    Hamster.report(message: message, to: channel)
  end

end
