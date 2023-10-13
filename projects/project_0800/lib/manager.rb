require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper = Scraper.new
  end

  def download
    already_downloaded_files = peon.list(subfolder: "#{keeper.run_id}") rescue []
    last_file = already_downloaded_files.sort.last rescue nil
    name_array = (last_file.nil?) ? array_formation("aa") : array_formation(last_file.gsub("_",""))
    name_array.each do |name|
      main_page_res = scraper.main_page("https://www.dpscs.state.md.us/inmate/")
      cookie = main_page_res.headers['set-cookie']
      name_page_response = scraper.main_request(name[0], name[1], cookie)
      next if name_page_response.body.include? "No Inmate Found."

      final_page_num = parser.get_page_num(name_page_response.body)
      if (final_page_num > 15)
        handle_pagination(final_page_num, name[0], name[1], cookie)
      else
        path = "#{keeper.run_id}/#{name[0]}_#{name[1]}/records_1"
        save_file(name_page_response.body, "records_1", path)
        inner_links = parser.get_inner_links(name_page_response.body)
        downloaded_files = peon.list(subfolder: path).reject{|e| e.include? "records_#{start_page}.gz"} rescue []
        download_inner_links(inner_links, path, downloaded_files, cookie)
      end
    end
    scraper.close_browser
  end

  def store
    downloaded_alphabets = peon.list(subfolder: "#{keeper.run_id}")
    downloaded_alphabets.each do |alphabet|
      records_folders = peon.list(subfolder: "#{keeper.run_id}/#{alphabet}")
      records_folders.each do |page|
        all_files = peon.list(subfolder: "#{keeper.run_id}/#{alphabet}/#{page}")
        main_page = all_files.select{|e| e.include? "records"}[0]
        main_page_html = peon.give(subfolder: "#{keeper.run_id}/#{alphabet}/#{page}", file: main_page)
        process_inner_links(main_page_html, "#{keeper.run_id}", alphabet, page, all_files)
      end
    end
    keeper.mark_deleted
    keeper.finish
    keeper.close_connection
  end

  private

 attr_accessor :parser, :keeper, :scraper

  def array_formation(name)
    array = ("aa".."zz").map(&:to_s)
    idx = array.find_index(name)
    array[idx..]
  end

  def process_inner_links(main_page_html, run_id, alphabet, page, all_files)
    inner_links = parser.get_inner_links(main_page_html)
    inner_links.each do |link|
      folder_name = link.split("=").last
      next if all_files.exclude? folder_name

      path = "#{run_id}/#{alphabet}/#{page}"
      link_file         = peon.give_list(subfolder: "#{path}/#{folder_name}")
      link_file_html    = peon.give(subfolder: "#{path}/#{folder_name}", file: link_file[0])
      inmates_data_hash = parser.parse_inmate_hash(link_file_html, run_id)
      inmate_id         = keeper.insert_inmates(inmates_data_hash)
      inmate_ids_hash          = parser.parse_inmate_ids_hash(link_file_html, inmate_id, run_id)
      inmate_ids_additional_id = keeper.insert_inmate_ids(inmate_ids_hash)
      inmate_additional_id_hash = parser.additional_inmate_hash(link_file_html, inmate_ids_additional_id, run_id)
      keeper.additional_inmate(inmate_additional_id_hash)
      keeper.update_touched_run_id(inmates_data_hash[:md5_hash], inmate_ids_hash[:md5_hash], inmate_additional_id_hash[:md5_hash])
      next if peon.list(subfolder: "#{path}/#{folder_name}").exclude? "facility"

      facility_file = peon.give_list(subfolder: "#{path}/#{folder_name}/facility")
      facility_file_html = peon.give(subfolder: "#{path}/#{folder_name}/facility", file: facility_file[0])
      next if facility_file_html.size <= 39
      next if facility_file_html.include? "Proxy Authentication Required"
      next if facility_file_html.include? "This error means that the file"
      next if facility_file_html.include? "404 - File or directory not found."

      facility_data_process(facility_file_html, run_id)
    end
  end

  def facility_data_process(html, run_id)
    facility_hash = parser.parse_facility_data(html, run_id)
    holding_facilities_id = keeper.insert_facility_hash(facility_hash)
    holding_facilities_hash = parser.holding_facilities(html, holding_facilities_id, run_id)
    facilities_additional_hash = parser.additional_facilities(holding_facilities_id, html, run_id)
    keeper.facility_touched_run_id_update(facility_hash[:md5_hash], facilities_additional_hash[:md5_hash], holding_facilities_hash[:md5_hash])
    keeper.insert_additional_facility(facilities_additional_hash, holding_facilities_hash)
  end

  def handle_pagination(final_page_num, f_name, l_name, cookie)
    downloaded_pages = peon.list(subfolder: "#{keeper.run_id}/#{f_name}_#{l_name}") rescue []
    start_page = downloaded_pages.empty? ? 1 : downloaded_pages.sort.last.split("s")[1].to_i
    while start_page <= final_page_num
      pages_response = scraper.pagination_request(f_name, l_name, start_page, cookie)
      path = "#{keeper.run_id}/#{f_name}_#{l_name}/records#{start_page}"
      save_file(pages_response.body, "records_#{start_page}", path)
      inner_links = parser.get_inner_links(pages_response.body)
      links_downloaded = peon.list(subfolder: path).reject{|e| e.include? "records_#{start_page}.gz"} rescue []
      download_inner_links(inner_links, path, links_downloaded, cookie)
      start_page += 15
    end  
  end

  def download_inner_links(inner_links, path, links_downloaded, cookie)
    inner_links.each do |link|
      file_name = create_file_name(link)
      folder_name = link.split("=").last
      next if links_downloaded.include? folder_name rescue nil

      link_response = scraper.inner_link_request(link, cookie)
      next if link_response.body.include? "No Inmate Found."
      save_file(link_response.body, file_name, "#{path}/#{folder_name}")

      facility_link = parser.get_facility_link(link_response.body)
      next if facility_link.exclude? "locations"

      facility_link_response = facility_request_retries(facility_link)
      next if facility_link_response.size <= 39
      next if facility_link_response.include? "Proxy Authentication Required"
      next if facility_link_response.include? "This error means that the file"
      next if facility_link_response.include? "404 - File or directory not found."

      facility_file_name = create_file_name(facility_link)
      save_file(facility_link_response, file_name, "#{path}/#{folder_name}/facility")
    end
  end

  def facility_request_retries(retries = 10, facility_link)
    begin
      scraper.facility_request(facility_link)
    rescue
      raise if (retries < 1)
      scraper.facility_request(retries -1, facility_link)
    end
  end

  def create_file_name(link)
    Digest::MD5.hexdigest link
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

end
