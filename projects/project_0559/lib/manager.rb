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
  end

  def download
    return if keeper.download_status(keeper.run_id)[0].to_s == "true"
    main_page, cookie = landing_page
    page = parser.parsing(main_page.body)
    all_states = parser.fetch_states(page)
    db_links = keeper.db_inserted_links
    starting_index, current_page, already_downloaded_files_for_state = resume(all_states)
    all_states[starting_index..-1].each_with_index do |state, index|
      current_page = 0 if index == 1
      main_page, cookie = landing_page
      page = parser.parsing(main_page.body)
      body = parser.get_main_body(page)
      unless state == 'Iowa'
        response = scraper.post_page_request(body, cookie, state)
        save_file("#{keeper.run_id}/#{state.split.join('_')}/page_1", response.body, "source_page")
        pp = parser.parsing(response.body)
        cookie = response.headers["set-cookie"]
        pagination(pp, cookie, state, current_page, already_downloaded_files_for_state, db_links)
      else
        all_cities = keeper.fetch_cities
        starting_index, current_page, already_downloaded_files_for_state = resume_cities(all_cities)
        all_cities[starting_index..-1].each_with_index do |city, city_index|
          current_page = 0 if city_index == 1
          response = scraper.post_page_request(body, cookie, state, city)
          save_file("#{keeper.run_id}/#{state.split.join('_')}/#{city.scan(/[A-Za-z]/).join}/page_1", response.body, "source_page")
          pp = parser.parsing(response.body)
          cookie = response.headers["set-cookie"]
          pagination(pp, cookie, state, current_page, already_downloaded_files_for_state, db_links, city)
        end
      end
    end
    keeper.mark_download_status(keeper.run_id)
  end

  def store
    if keeper.download_status(keeper.run_id)[0].to_s == "false"
      full_message = "Either download is still running or there's an issue with downloader"
      Hamster.report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{full_message}", use: :slack)
      return
    end
    already_inserted_md5 = keeper.fetch_db_inserted_md5_hash
    alphabets_folders = peon.list(subfolder: "#{keeper.run_id}")
    alphabets_folders.each do |folder|
      inner_folders = peon.list(subfolder: "#{keeper.run_id}/#{folder}").sort
      inner_folders.each do |inner_folder|
        if folder == "Iowa"
          page_folders = peon.list(subfolder: "#{keeper.run_id}/#{folder}/#{inner_folder}").sort
          page_folders.each do |page_folder|
            files = peon.give_list(subfolder: "#{keeper.run_id}/#{folder}/#{inner_folder}/#{page_folder}").sort
            parsing_files(files, folder, inner_folder, page_folder, already_inserted_md5)
          end
        else
          files = peon.give_list(subfolder: "#{keeper.run_id}/#{folder}/#{inner_folder}").sort
          parsing_files(files, folder, inner_folder, already_inserted_md5)
        end
      end
    end
    keeper.mark_deleted unless already_inserted_md5.empty?
    keeper.update_missing_records
    keeper.delete_duplicates
    keeper.finish
    tars_to_aws
  end

  private
  attr_accessor :keeper, :parser, :scraper

  def landing_page
    main_page = scraper.main_page
    cookie = main_page.headers["set-cookie"]
    [main_page, cookie]
  end

  def parsing_files(files, folder, inner_folder, page_folder = '', already_inserted_md5)
    path = (page_folder.empty?)? "#{keeper.run_id}/#{folder}/#{inner_folder}" : "#{keeper.run_id}/#{folder}/#{inner_folder}/#{page_folder}"
    main_page = peon.give(subfolder: path, file: "source_page") rescue nil
    return if main_page.nil?
    main_page = parser.parsing(main_page)
    links = parser.links(main_page)
    licensing_board = parser.licensing_board(main_page)
    data_array, array_deleted = [], []
    links.each_with_index do |link, index|
      file = Digest::MD5.hexdigest link
      file_data = peon.give(subfolder: path, file: file) rescue nil
      next if file_data.nil?
      data_hash = parser.get_data(file_data, "#{keeper.run_id}", licensing_board[index], link, folder)
      if already_inserted_md5.include? data_hash[:md5_hash]
        array_deleted << data_hash[:md5_hash]
        already_inserted_md5.delete data_hash[:md5_hash]
        next
      end
      data_array << data_hash unless data_hash.nil?
    end
    keeper.insert_records(data_array)
    keeper.update_touched_run_id(array_deleted)
  end

  def pagination(pp, cookie, state, current_page, already_downloaded_files_for_state, db_links, city = '')
    page_no = 1
    while true
      cookie, page_no, pp = skip_pages(page_no, current_page, pp, cookie)
      data_links_info(parser.links(pp), state, already_downloaded_files_for_state, page_no, city, db_links)
      break if parser.next_btn(pp)
      page_no += 1

      page_body = parser.get_page_body(pp)
      pagination_request = scraper.paginate(page_body, cookie)

      save_file_check(state, page_no, pagination_request, "source_page", city)
      cookie  = pagination_request.headers["set-cookie"]

      pp = parser.parsing(pagination_request.body)
    end
  end

  def skip_pages(page_no, current_page, pp, cookie)
    while page_no < current_page
      page_body = parser.get_page_body(pp)
      pagination_request = scraper.paginate(page_body, cookie)
      cookie  = pagination_request.headers["set-cookie"]
      pp = parser.parsing(pagination_request.body)
      page_no += 1
    end
    [cookie, page_no, pp]
  end

  def save_file_check(state, page_no, response, filename, city)
    unless city.empty?
      save_file("#{keeper.run_id}/#{state.split.join('_')}/#{city.scan(/[A-Za-z]/).join}/page_#{page_no.to_s}", response.body, filename)
    else
      save_file("#{keeper.run_id}/#{state.split.join('_')}/page_#{page_no.to_s}", response.body, filename)
    end
  end

  def data_links_info(links, state, already_downloaded_files_for_state, page_no, city, db_links)
    links.each do |link|
      next if db_links.include? link
      file_name = Digest::MD5.hexdigest link
      next if already_downloaded_files_for_state.include? "#{file_name}"
      response = scraper.fetch_link(link)
      save_file_check(state, page_no, response, file_name, city)
    end
  end

  def create_tar
    path = "#{storehouse}store"
    time = Time.parse(Time.now.to_s).strftime('%Y-%m-%d').to_s
    file_name = (keeper.run_id) ? "#{path}/#{time}_#{keeper.run_id}.tar" : "#{path}/#{time}.tar"
    File.open(file_name, 'wb') { |tar| Minitar.pack(Dir.glob("#{path}"), tar) }
    move_folder("#{path}/*.tar", "#{storehouse}trash")
    clean_dir(path)
    file_name
  end

  def clean_dir(path)
    FileUtils.rm_rf("#{path}/.", secure: true)
  end

  def move_folder(folder_path, path_to)
    FileUtils.mv(Dir.glob("#{folder_path}"), path_to)
  end

  def directory_size(path)
    require 'find'
    size = 0
    Find.find(path) do |f|
      size += File.stat(f).size
    end
    size
  end

  def tars_to_aws
    s3 = AwsS3.new(:hamster,:hamster)
    create_tar
    path = "#{storehouse}trash"
    if (directory_size("#{path}").to_f / 1000000).round(2) > 1000 # Mb
      Dir.glob("#{path}/*.tar").each do |tar_path|
        content = IO.read(tar_path)
        key = tar_path.split('/').last
        s3.put_file(content, "tasks/scrape_tasks/st0#{Hamster::project_number}/#{key}", metadata = {})
      end
      clean_dir(path)
    end
  end

  def resume(all_states)
    last_state = peon.list(subfolder: "#{keeper.run_id}").sort.last rescue []
    return [0,0, []] if last_state.nil? || last_state.empty?
    last_sub_folder = peon.list(subfolder: "#{keeper.run_id}/#{last_state}").sort.last
    state_index = all_states.map{|e| e.gsub(" ","_")}.index last_state
    already_downloaded_files_for_state = fetch_state_downloaded_files("#{all_states[state_index]}")
    current_page = last_sub_folder.scan(/[0-9]/).last.to_i rescue 0
    [state_index, current_page, already_downloaded_files_for_state]
  end

  def resume_cities(all_cities)
    last_city = peon.list(subfolder: "#{keeper.run_id}/Iowa").sort.last rescue []
    return [0, 0, []] if last_city.nil? || last_city.empty?
    city_index = all_cities.map{|e| e.scan(/[A-Za-z]/).join}.index last_city
    current_page = peon.list(subfolder: "#{keeper.run_id}/Iowa/#{last_city}").map{|e| e.split('_').last.to_i}.max
    already_downloaded_files_for_cities = fetch_state_downloaded_files("Iowa/#{last_city}")
    [city_index, current_page, already_downloaded_files_for_cities]
  end

  def fetch_state_downloaded_files(folder_path)
    all_sub_folders = peon.list(subfolder: "#{keeper.run_id}/#{folder_path}")
    downloaded_files = []
    all_sub_folders.each do |sub_folder|
      downloaded_files << peon.list(subfolder: "#{keeper.run_id}/#{folder_path}/#{sub_folder}").reject{|e| e.include? "source_page"}.map{|e| e.gsub(".gz","")}
    end
    downloaded_files.flatten.uniq
  end

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end
end
