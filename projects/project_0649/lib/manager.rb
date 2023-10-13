# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
    @run_id = keeper.run_id.to_s
  end

  def run
    download
    store
  end

  def download
    dates_array = get_dates_array
    dates_array.each do |date|
      date = date.to_s
      outer_folder = date.gsub('-', '_')
      links, cookie, main_url = initial_data(date)
      if links.count == 1000
        deep_search(date, outer_folder)
      else
        download_inner_pages(links, cookie, outer_folder, main_url)
      end
    end
    download_db_records
    keeper.finish_download
  end

  def store
    dates_folders = peon.list(subfolder: run_id) rescue []
    dates_folders.each do |date_folder|
      get_folder_data(date_folder)
    end
    keeper.mark_deleted if keeper.download_status == "finish"
    keeper.finish if keeper.download_status == "finish"
    FileUtils.rm_rf Dir.glob("#{storehouse}/store/#{run_id}*") if keeper.download_status == "finish"
  end

  private

  def download_db_records
    all_links = keeper.get_already_inserted_links.uniq
    all_links.each_slice(1000) { |links|
      response = scraper.fetch_cookies
      cookie = get_cookie(response.headers['set-cookie'])
      url = "https://propublic.buckscountyonline.org/PSI/v/search/case?Q=&IncludeSoundsLike=false&Count=1000&fromAdv=1&CaseNumber=&LegacyCaseNumber=&ParcelNumber=&CaseType=&DateCommencedFrom=&DateCommencedTo=&FilingType=&FilingDateFrom=01%2F03%2F2016&FilingDateTo=01%2F03%2F2016&JudgeID=&Attorney=&AttorneyID=&Grid=true"
      download_inner_pages(links, cookie, 'additional_records', url)
    }
  end

  def get_folder_data(folder)
    info_md5_array = []
    activities_md5_array = []
    party_md5_array = []
    judgment_md5_array = []
    files = peon.give_list(subfolder: "#{run_id}/#{folder}")
    files.each do |file|
      data_file = peon.give(subfolder: "#{run_id}/#{folder}", file: file)
      data = parser.fetch_info(data_file, file, run_id)
      next if data.empty?

      info_md5_array << data[0][0][:md5_hash] unless data[0].nil?
      party_md5_array <<  data[1].map { |e| e[:md5_hash] } unless data[1].empty?
      activities_md5_array << data[2].map { |e| e[:md5_hash] } unless data[2].empty?
      judgment_md5_array << data[3].map { |e| e[:md5_hash]} unless data[3].empty?
      keeper.insert_data(data)
    end
    keeper.update_touch_run_id(info_md5_array, party_md5_array, activities_md5_array, judgment_md5_array)
  end

  def deep_search(start_key = 'a', end_key = 'z', date, outer_folder)
    (start_key..end_key).each do |search_key|
      all_links, cookie, main_url = initial_data(date, search_key)
      if all_links.count == 1000
        deep_search("#{search_key}a", "#{search_key}z", date, outer_folder)
      else
        download_inner_pages(all_links, cookie, outer_folder, main_url)
      end
    end
  end

  def initial_data(date, key = '')
    response = scraper.fetch_cookies
    cookie = get_cookie(response.headers['set-cookie'])
    main_page_response, main_url = scraper.main_page_request(cookie, key, date)
    all_links = parser.get_links(main_page_response.body)
    [all_links, cookie, main_url]
  end

  def download_inner_pages(all_links, cookie, subfolder, main_url)
    return [] if all_links.empty?

    all_links = remove_already_downloaded_records(all_links)
    all_links.each do |link|
    file_name = link.split('/').last
    response = scraper.inner_page_request(link, cookie, main_url)
    save_file(response.body, file_name, "#{run_id}/#{subfolder}")
    end
  end

  def remove_already_downloaded_records(all_links)
    already_downloaded_files = get_already_downloaded_files
    all_links.reject { |e| already_downloaded_files.include? e.split('/').last + '.gz'}
  end

  def get_already_downloaded_files
    all_files = []
    dates_folders = peon.list(subfolder: run_id) rescue []
    dates_folders.each do |folder|
      already_downloaded_files = peon.give_list(subfolder: "#{run_id}/#{folder}")
      all_files = all_files + already_downloaded_files
    end
    all_files.uniq
  end

  def get_cookie(cookie)
    cookie = cookie.split(';')
    seesion_id = cookie[0]
    user_guid = cookie.select { |e| e.include? 'PSIUserGuid' }[0].split(',')[1]
    auth_bucks = cookie.select { |e| e.include? 'PSIAuth_Bucks' }[0].split(',')[1]
    "#{seesion_id}; #{user_guid}; #{auth_bucks}"
  end

  def get_dates_array
    latest_folder = keeper.max_case_file_date
    latest_folder = Date.parse('01-01-2018') if latest_folder.nil?
    ((latest_folder)..(Date.today))
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  attr_accessor :keeper, :parser, :scraper, :run_id
end
