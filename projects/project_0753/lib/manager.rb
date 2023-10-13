require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @parser      = Parser.new
    @scraper     = Scraper.new
    @keeper      = Keeper.new
    @run_id      = keeper.run_id
    @already_fetched_records = keeper.already_fetched_records
  end

  def run_script
    (keeper.download_status == "finish") ? store : download
  end

  def download
    start = peon.list(subfolder: "#{keeper.run_id}") rescue []
    page_body = scraper.connect_to("https://sbaprolife.org/scorecard").body
    if !start.include?("source.gz")
      save_file(page_body, "source", "#{keeper.run_id}")
    end
    main_page = parser.parse_page(page_body)
    process_links(main_page)
    keeper.finish_download
    store
  end

  def store
    all_folders = peon.list(subfolder: "#{keeper.run_id}").sort.reject { |folder| folder =~ /source/ }
    main_page = peon.give(subfolder: "#{keeper.run_id}", file: "source.gz")
    res = usa_states_download
    links = parser.get_main_page_link(main_page)
    links.each do |link|
      next if @already_fetched_records.include?(link)
      type = link.include?("senator") ? "senator" : "representative"
      folder_name = "#{type}"
      file_name = Digest::MD5.hexdigest(link)
      folder = all_folders.find { |f| f.include?(folder_name) }
      file = peon.give(subfolder: "#{keeper.run_id}/#{folder}", file: "#{file_name}.gz")
      file_data = parser.file_data_check(file)
      next if file_data.text.empty?
      page = parser.parse_page(file)
      all_tabs = parser.get_tabs(page)
      process_tab(all_tabs, link, page, type, res)
    end
    keeper.delete_using_touch_id if keeper.download_status == "finish"
    keeper.finish if keeper.download_status == "finish"
  end

  def process_tab(all_tabs, link, page, type, res) 
    raw_vote_data_all, raw_activities_data_all = [], []
    raw_vote_md5_all, raw_activities_md5_all = [], []
    raw_house_hashes = []

    raw_senate_hash, raw_hash  = parser.get_outer_details(page, link, res, @run_id)

    all_tabs.each do |tab|
      cong_num   = tab.next_element.text.squish.split('th').first
      html       = tab.next_element.next_element
      raw_vote_data_combined, raw_activities_hash, raw_vote_md5_combined, raw_activities_md5_array = parser.fetch_data(html, link, @run_id, cong_num)
      raw_house_hash = parser.get_house_person_details(html, link, @run_id)
      raw_house_hashes.push(raw_house_hash)
      raw_vote_data_all       = concat_arrays(raw_vote_data_all, raw_vote_data_combined)
      raw_activities_data_all = concat_arrays(raw_activities_data_all, raw_activities_hash)
      raw_vote_md5_all        = concat_arrays(raw_vote_md5_all, raw_vote_md5_combined)
      raw_activities_md5_all  = concat_arrays(raw_activities_md5_all, raw_activities_md5_array)
    end
    make_insertions(type, raw_senate_hash, raw_hash, raw_house_hashes, raw_vote_data_all, raw_activities_data_all, raw_vote_md5_all, raw_activities_md5_all)
  end

  private
  attr_reader   :parser
  attr_accessor :keeper, :scraper, :run_id

  def make_insertions(type, raw_senate_hash, raw_hash, raw_house_hashes, raw_vote_data_all, raw_activities_data_all, raw_vote_md5_all, raw_activities_md5_all)
    person_id = keeper.insert_person(raw_hash, Sba_List_Scorecard_Raw_Person)
    raw_senate_md5_array = []
    raw_hash_md5_array = []
    raw_vote_md5_array = raw_vote_data_all.map{|e| e[:md5_hash]}
    raw_activities_md5_array = raw_activities_data_all.map{|e| e[:md5_hash]}
    raw_house_md5_array = []
    raw_house_hashes.each do |raw_house_hash|
      senate_house_hash = type == "senator" ? raw_senate_hash : raw_house_hash
      raw_md5_array = type == "senator" ? raw_senate_md5_array : raw_house_md5_array
      senate_house_hash[:person_id] = person_id
      raw_md5_array << senate_house_hash[:md5_hash]
      senate_house_hash.delete(:md5_hash)
    end
    (raw_vote_data_all + raw_activities_data_all).each { |data| data[:person_id] = person_id; data.delete(:md5_hash) }
    if type == "senator"
      keeper.insert_senate_hash(raw_senate_hash, raw_hash, raw_vote_data_all, raw_activities_data_all)
    else
      keeper.insert_representative_hash(raw_hash, raw_house_hashes, raw_vote_data_all, raw_activities_data_all)
    end
    keeper.update_touch_run_id(raw_senate_md5_array, raw_hash_md5_array, raw_house_md5_array, raw_vote_md5_array, raw_activities_md5_array)
  end

  def concat_arrays(*arrays)
    combined_array = []
    arrays.each do |array|
      combined_array.concat(array)
    end
    combined_array
  end

  def usa_states_download
    page = scraper.connect_to("https://uk.usembassy.gov/states-of-the-union-states-of-the-u-s/")
    parser.parse_page(page.body)
  end

  def process_links(main_page)
    links = parser.get_senate_house_links(main_page)
    downloaded_links = links.map { |link| download_link(link) }
  end

  def download_link(link)
    file_name = Digest::MD5.hexdigest(link)
    subfolder = link.include?("senator") ? "#{keeper.run_id}/senator" : "#{keeper.run_id}/representative"
    downloaded_files = peon.give_list(subfolder: subfolder)
    if downloaded_files.exclude?("#{file_name}.gz")
      response = scraper.connect_to(link)
      save_file(response.body, file_name, subfolder)
    end
  end
  
  def save_file(body, file_name, sub_folder)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end
end
