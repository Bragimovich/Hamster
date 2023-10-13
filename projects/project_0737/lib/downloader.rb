module Downloader
  
  def search_inmates(first_name, current_start = 1)
    cookies = scraper.get_cookie
    
    unless cookies.nil?
      logger.debug "searching #{first_name}, #{current_start}"
      search_html = scraper.download_search(first_name)
      inmates_ids = parser.page(search_html).inmates_ids
      # current_start = parser.current_start.to_i
      last_page = parser.last_page.to_i
      logger.debug("current page #{current_start}, last page #{last_page}")
      download_inmates(inmates_ids)
      search_inmates_paginated(first_name,current_start,last_page)
    end
  end

  def search_inmates_paginated(first_name,current_start,last_page)
    logger.debug("search_inmates_paginated(#{first_name},#{current_start},#{last_page})")
    last_page = 1 if last_page < 1
    while current_start < last_page
      first_name,current_start,last_page = *download_next_inmates(first_name,current_start,last_page)
      # store in db after every 10,000 record and delete hmtl downloaded files
      logger.debug("store_in_db: #{(current_start % 1000)}")
      store_in_db(false) if((current_start.to_i % 1000) < 2)
    end
  end

  def download_next_inmates(first_name,current_start,last_page)
    search_html = scraper.download_next(current_start)
    inmates_ids = parser.page(search_html).inmates_ids
    current_start = parser.current_start.to_i
    last_page = parser.last_page.to_i
    logger.debug("first_name: #{first_name}, current page #{current_start}, last page #{last_page}")
    download_inmates(inmates_ids)
    keeper.update_current_start(current_start)
    [first_name,current_start,last_page]
  end

  def download_inmates(inmates_ids)
    logger.debug("download_inmates #{inmates_ids.length}")
    unless inmates_ids.empty?
      inmates_ids.each do |inmate|
        sys_id,img_sys_id = inmate
        download_inmate(sys_id.to_s,img_sys_id.to_s)
        sleep(1)
      end
    end
  end

  private

  def save_file(html, file_name, sub_folder)
    peon.put content: html, file: file_name.to_s, subfolder: sub_folder
  end

  def file_name(link)
    Digest::MD5.hexdigest link
  end

  def inmate_folder
    "#{keeper.run_id}"
  end

  def search_folder
    "#{inmate_folder}/search"
  end

  def dump_search_html(html,character)
    logger.debug "dumping search #{file_name(character)}"
    save_file(html, file_name(character), search_folder) unless html.nil?
  end

  def search_downloaded?(file)
    storage_path = "#{storehouse}/store/#{search_folder}/#{file_name(file)}.gz"
    File.exists?(storage_path)
  end
  

  def attach_run_id!(hash)
    hash.merge!(touched_run_id: keeper.run_id,run_id: keeper.run_id)
  end

  def inmate_downloaded?(file)
    storage_path = "#{storehouse}store/#{inmate_folder}/#{file_name(file)}.gz"
    File.exists?(storage_path)
  end

  def download_inmate(sys_id,img_sys_id)
    file = "#{sys_id}_#{img_sys_id}"
    unless inmate_downloaded?(file)
      inmate_html = scraper.download_inmate(sys_id,img_sys_id)

      dump_inmate_html(inmate_html,file) if parser.page(inmate_html).valid_inmate_page?
    end
  end

  def dump_inmate_html(html,file)
    logger.debug "dumping inmate html "
    save_file(html, file_name(file), inmate_folder) unless html.nil?
  end

  def store_in_db(finished = true)
    inmate_files = peon.give_list(subfolder: inmate_folder).sort
    inmate_files.map do |inmate_file|
      logger.debug "processing file #{inmate_file}"
      inmate_html = peon.give(file: inmate_file,subfolder: inmate_folder)
      inmate = parser.page(inmate_html).parse_inmates
      # keeper.store(inmate)
      file_path = "#{storehouse}store/#{keeper.run_id}/#{inmate_file}"
      logger.debug "removing file #{file_path}"
      FileUtils.rm_rf(file_path)
    end
    keeper.finish if finished
  end
end
