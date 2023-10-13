# frozen_string_literal: true

require_relative '../models/nm_lawyer_status_runs'

class NMLawyerStatusScraper < Hamster::Scraper

  SOURCE = 'https://www.sbnm.org/'
  # SUB_PATH = 'cvweb/cgi-bin/utilities.dll/customList?QNAME=FINDALAWYER&WHP=LawyerList_header.htm&WBP=LawyerList.htm&RANGE=0/20000&SORT=LONGSALUTATION&SHOWSQL=N&DISPLAYLAWYERPROFILE=N'
  SUB_PATH = 'cvweb/cgi-bin/utilities.dll/customList?QNAME=FINDALAWYER&WHP=LawyerList_header.htm&WBP=LawyerList.htm&RANGE=0/20000&SORT=LASTNAME,FIRSTNAME&SHOWSQL=N&DISPLAYLAWYERPROFILE=N&LISTDESCRIPTION=Find%20a%20Lawyer'
  PROFILE_LINK = 'https://www.sbnm.org/cvweb/cgi-bin/utilities.dll/customList?QNAME=FINDALAWYER&WHP=none&WBP=LawyerProfilex.htm&customercd='

  def initialize
    super
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @run_id = nil
  end

  def start
    Hamster.report(to: 'Alim Lumanov', message: "Project #154 download started")
    log_download_started

    tar_store_to_trash
    download

    log_download_finished
    Hamster.report(to: 'Alim Lumanov', message: "Project #154 download finished")
  rescue => e
    puts e, e.full_message
    Hamster.report(to: 'Alim Lumanov', message: "Project #154 - start:\n#{e}")
  end

  private

  def download
    index_raw = download_index
    save_index(index_raw)
    download_index_items(index_raw)
  end

  def download_index
    url = SOURCE + SUB_PATH
    connect_to(url, proxy_filter: @filter, ssl_verify: false)&.body
  rescue StandardError => e
    puts e, e.full_message
    Hamster.report(to: 'Alim Lumanov', message: "Project #154 - download_index:\n#{e}")
  end

  def save_index(page)
    file_name = 'index'
    index_folder = @run_id.to_s.rjust(4, "0") + '_index'
    save_file(page, file_name, index_folder)
  end

  def download_index_items(page)
    records = Nokogiri::HTML(page).at('#myTable tbody').css('tr')
    records.each_with_index do |record, idx|
      next if record.nil?
      download_record(record, idx)
    end
  end

  def download_record(record, record_num)
    bar_number = record.css('td').css('a').last['onclick'].split(',').last.gsub("'", '').gsub(")", '')
    page_link = "#{PROFILE_LINK}#{bar_number}"
    page = connect_to(page_link, proxy_filter: @filter, ssl_verify: false)&.body
    save_record(page, record_num)
  rescue StandardError => e
    puts e, e.full_message
    Hamster.report(to: 'Alim Lumanov', message: "Project #154 - download_record:\n#{e}")
  end

  def save_record(page, record_num)
    file_name = "#{record_num.to_s.rjust(5, "0")}"
    records_folder = @run_id.to_s.rjust(4, "0") + '_records'
    save_file(page, file_name, records_folder)
  end

  def save_file(html, name, folder)
    peon.put content: html, file: name, subfolder: folder
  end

  def tar_store_to_trash
    pre_run_id = @run_id.to_i - 1
    run_name_justified = pre_run_id.to_s.rjust(4, "0")
    tar_file = "#{run_name_justified}.tar"
    src_dir = "#{@_storehouse_}store/"
    dest_dir = "#{@_storehouse_}trash/"
    Minitar.pack(src_dir, File.open("#{dest_dir}#{tar_file}", 'wb'))
    FileUtils.rm_r Dir.glob("#{src_dir}*")
  end

  def log_download_started
    current_run = NMLawyerStatusRuns.create(status: 'download started')
    @run_id = current_run.id
    puts "#{"="*50} download started #{"="*50}"
  end

  def log_download_finished
    NMLawyerStatusRuns.find(@run_id).update(status: 'download finished')
    puts "#{"="*50} download finished #{"="*50}"
  end

end
