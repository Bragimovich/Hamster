require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @parser   = Parser.new
    @keeper   = Keeper.new
    @scraper  = Scraper.new
    @run_id   = @keeper.run_id
    @aws_s3   = AwsS3.new(bucket_key = :hamster, account=:hamster)
  end

  attr_accessor :keeper, :run_id, :aws_s3

  def run
    (keeper.download_status == "finish") ? store : download
  end

  def download
    main_page = scraper.landing_page
    search_res = scraper.search_page
    cookie = search_res.headers['set-cookie']
    response = scraper.results_page(cookie)
    max_folder, downloaded_files = resume_page
    page_num, response = skip_pages(max_folder, cookie, response)
    while true
      save_file(response, "source_page_#{page_num}", "#{keeper.run_id}/#{page_num}")
      page = parse_page(response.body)
      all_links = parser.get_inmate_links(page)
      download_inner_pages(all_links, page_num, downloaded_files)
      next_flag, next_url = parser.find_next_page(page)
      break if next_flag
      page_num += 1
      response = scraper.pagination(cookie, next_url)
    end
    keeper.finish_download
    store
  end

  def store
    scraper.mechanize_con
    all_folders = peon.list(subfolder: "#{run_id}").sort rescue []
    all_folders.each do |folder|
      source_file = peon.list(subfolder: "#{run_id}/#{folder}").keep_if{|e| e.include? 'source'}[0]
      source_page = peon.give(subfolder: "#{run_id}/#{folder}", file: "#{source_file}")
      document = parser.parse_page(source_page)
      all_links =  parser.get_inmate_links(document)
      process_links(all_links, folder)
    end
    if (keeper.download_status == "finish")
      keeper.marked_deleted
      keeper.finish
    end  
  end

  private
  attr_accessor :parser, :scraper, :keeper

  def skip_pages(max_folder, cookie, response)
    page_num = 1
    while page_num < max_folder
      page_num += 1
      page = parse_page(response.body)
      next_flag, next_url = parser.find_next_page(page)
      break if next_flag
      response = scraper.pagination(cookie, next_url)
    end
    [page_num, response]
  end

  def download_inner_pages(all_links, page_num, downloaded_files)
    all_links.each do |link|
      file_name = Digest::MD5.hexdigest link
      next if downloaded_files.include? (file_name)
      response  = scraper.get_inner_page(link)
      page = parse_page(response.body)
      save_file(response, file_name, "#{keeper.run_id}/#{page_num}")
    end
  end

  def process_links(all_links, folder)
    court_hearing_array, holding_facilities_array, additional_info_array, maine_statuses_array, inmate_aliases_array = [], [], [], [], []
    all_links.each do |link|
      file_name  = Digest::MD5.hexdigest link
      html = peon.give(subfolder: "#{run_id}/#{folder}", file: "#{file_name}") rescue nil
      next if html.nil?
      document = parser.parse_page(html)
      count = document.css('table.at-data-table tr').count
      check = parser.check_data(document)
      next if check.nil?
      next if count < 3
      inmate_id = inmates_fun(document, link)
      arrest_id = arrests_fun(document, link, inmate_id)
      inmate_ids_insertion = inmate_ids_fun(document, link, inmate_id)
      holding_facilities = parser.get_maine_holding_facilities(document, link, run_id, arrest_id)
      holding_facilities_array << holding_facilities
      mugshots_hash = maine_mugshots_fun(document, link, inmate_id)
      additional_info = parser.get_maine_additional_info(document, run_id, inmate_id)
      additional_info_array << additional_info
      maine_statuses = parser.get_maine_statuses(document, link, run_id, inmate_id)
      maine_statuses_array << maine_statuses
      inmate_aliases = parser.get_maine_inmate_aliases(document, link, run_id, inmate_id)
      inmate_aliases_array << inmate_aliases
      charges_ids = charges_ids_fun(document, link, arrest_id)
      next if charges_ids.nil?
      court_hearing  = parser.get_court_hearings(document, link, run_id, charges_ids)
      court_hearing_array << court_hearing
    end
    keeper.insert_data(court_hearing_array.flatten, 'maine_court_hearings')
    keeper.insert_data(holding_facilities_array.flatten, 'maine_holding_facilities')
    keeper.insert_data(additional_info_array.flatten, 'maine_inmate_additional_info')
    keeper.insert_data(maine_statuses_array.flatten, 'maine_inmate_statuses')
    keeper.insert_data(inmate_aliases_array.flatten, 'maine_inmate_aliases')
  end

  def inmates_fun(document, link)
    inmates_data_hash = parser.get_maine_inmates(document, link, run_id)
    keeper.insert_for_foreign_key(inmates_data_hash, 'maine_inmates')
  end

  def arrests_fun(document, link, inmate_id)
    arrests_data_hash = parser.get_arrests_data(document, link, run_id, inmate_id)
    keeper.insert_for_foreign_key(arrests_data_hash, 'maine_arrests')
  end

  def inmate_ids_fun(document, link, inmate_id)
    inmate_ids_hash = parser.get_inmate_ids(document, link, run_id, inmate_id)
    keeper.insert_for_foreign_key(inmate_ids_hash, 'maine_inmate_ids')
  end

  def charges_ids_fun(document, link, arrest_id)
    charges_array = parser.get_charges(document, link, run_id, arrest_id)
    insert_records(charges_array, 'maine_charges') unless charges_array.empty?
  end

  def maine_mugshots_fun(document, link, inmate_id)
    image_url = document.css('th.offender-profile').children.first['src']
    aws_link  = store_to_aws(image_url)
    maine_mugshots_hash = parser.maine_mugshots(document, link, run_id, inmate_id, aws_link, image_url)
    keeper.insert_data(maine_mugshots_hash, 'maine_mugshots')
  end

  def parse_page(page_body)
    parser.parse_page(page_body)
  end

  def file_already_downloaded(page_num)
    peon.list(subfolder: "#{keeper.run_id}/#{page_num}").reject{|e| e.include? 'source_page'}.map{|e| e.split('.gz').first} rescue []
  end

  def insert_records(data_array, key)
    id_array = []
    data_array.each do |data|
      id = keeper.insert_for_foreign_key(data, key)
      id_array << id
    end
    id_array
  end

  def resume_page
    max_folder = peon.list(subfolder: "#{keeper.run_id}").sort.map(&:to_i).max rescue nil
    return [1, []] if max_folder.nil?
    [max_folder, file_already_downloaded(max_folder)]
  end

  def store_to_aws(link)
    aws_url = "https://hamster-storage1.s3.amazonaws.com/"
    name = Digest::MD5.new.hexdigest(link)
    key = "crimes_mugshots/MA/#{name}.jpg"
    return (aws_url + key) unless @aws_s3.find_files_in_s3(key).empty?

    body = scraper.fetch_image(link)
    @aws_s3.put_file(body, key)
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html.body, file: file_name, subfolder: subfolder
  end
end  
