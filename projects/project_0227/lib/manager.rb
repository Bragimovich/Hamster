require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper  = Keeper.new
    @parser  = Parser.new
    @scraper = Scraper.new
    @error_count = 0
  end

  def download_individual_option
    return if keeper.download_status('individual') == 'finish'

    begin
      values_array = get_main_info
      download_license(values_array, 'individual')
    rescue Exception => e
      raise e.full_message if @error_count > 10
      @error_count +=1
      download_individual_option
      Hamster.logger.error(e.full_message)
      Hamster.report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
    end
    keeper.finish_download('individual')
  end

  def download_business_option
    return if keeper.download_status('business') == 'finish'

    begin
      values_array = get_main_info
      download_license(values_array, 'business')
    rescue Exception => e
      raise e.full_message if @error_count > 10
      @error_count +=1
      download_business_option
      Hamster.logger.error(e.full_message)
      Hamster.report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
    end
    keeper.finish_download('business')
  end

  def store
    return if (keeper.download_status('business') == 'processing') or ( keeper.download_status('individual') == 'processing')
    insert_records('individual')
    insert_records('business')
    keeper.mark_deleted
    keeper.finish
  end

  private

  def get_main_info
    main_page = scraper.fetch_main_page
    @parser.fetch_values(main_page.body)
  end

  def insert_records(type)
    @touch_run_ids_array = []
    boards_folders = peon.list(subfolder: "#{keeper.run_id}/#{type}").sort rescue []
    boards_folders.each do |board_folder|
      folders = peon.list(subfolder: "#{keeper.run_id}/#{type}/#{board_folder}").sort
      folders.each do |folder|
        sub_folder = "#{keeper.run_id}/#{type}/#{board_folder}/#{folder}"
        fetch_data_from_json_file(sub_folder)
      end
    end
    update_touch_run_ids
  end

  def fetch_data_from_json_file(sub_folder)
    data_array = []
    json_file  = peon.give(file: 'json_file.gz', subfolder: sub_folder)
    data_array, touch_id_array = parser.fetch_json_info(json_file, keeper.run_id)
    @touch_run_ids_array = @touch_run_ids_array + touch_id_array
    update_touch_run_ids if @touch_run_ids_array.count > 6000
    insert_data(data_array) unless data_array.empty?
  end

  def update_touch_run_ids
    keeper.update_rouch_id(@touch_run_ids_array) unless @touch_run_ids_array.empty?
    @touch_run_ids_array = []
  end

  def download_license(boards_array, type)
    already_downloaded_boards_folders = peon.list(subfolder: "#{keeper.run_id}/#{type}").sort[0..-2] rescue []
    boards_array = boards_array.reject { |b| already_downloaded_boards_folders.include? b.downcase.gsub(' ', '_').gsub('&', '_').gsub(',', '') }  rescue []
    boards_array.each do |board|
      download_json_files(board, type)
    end
  end

  def download_json_files(board, search_type)
    board_name = board.downcase.gsub(' ', '_').gsub('&', '_').gsub(',', '_')
    already_downloaded_folders = peon.list(subfolder: "#{keeper.run_id}/#{search_type}/#{board_name}").sort rescue []
    start_index_first  = already_downloaded_folders.last[0] rescue nil
    start_index_second = already_downloaded_folders.last[1] rescue nil
    start_index_first  = 'A' if start_index_first.nil?
    start_index_second = 'A' if start_index_second.nil?
    (start_index_first..'Z').each do |first_name|
      (start_index_second..'Z').each do |last_name|
        auth_page     = scraper.auth_page_request
        authorization = parser.fetch_auth(auth_page.body)
        response = scraper.data_request(board, search_type, authorization, first_name, last_name)
        sub_folder    = "#{keeper.run_id}/#{search_type}/#{board_name}/#{first_name}#{last_name}"
        save_file(response.body, 'json_file', sub_folder)
      end
    end
  end

  def insert_data(data_array)
    keeper.save_record(data_array)
  end

  def save_file(html, file_name, sub_folder)
    peon.put content: html, file: file_name, subfolder: sub_folder
  end

  attr_accessor :keeper, :parser, :scraper
end
