require_relative "../lib/scraper"
require_relative "../lib/parser"
require_relative "../lib/keeper"

class Manager <  Hamster::Harvester

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = @keeper.run_id.to_s
  end

  def run
    download
    store
  end

  private

  def download
    iteration = 1
    current_start = 1
    main_page = scraper.hit_main_page
    first_page_cookie = parser.get_main_page_cookie(main_page)
    loop do
      payload = scraper.prepare_payload(iteration: iteration, current_start: current_start)
      result_page = scraper.hit_result_page(first_page_cookie, payload)
      current_start+=30
      payload_ids = parser.get_payload_ids(result_page)
      break if payload_ids.empty?

      download_single_page(iteration, payload_ids, first_page_cookie)
      iteration += 1
    end
  end

  def download_single_page(iter, payload_ids, cookie)
    all_files = peon.give_list(subfolder: "#{run_id}/#{iter}") rescue []
    payload_ids.each_with_index do |payload, i|
      file_name =  "#{payload[0]}_#{payload[1]}"
      next if all_files.include? ("#{file_name}.gz")

      payload_data = scraper.prepare_payload(iteration: nil, sysID: payload[0], imgSysID: payload[1])
      internal_page_html = scraper.hit_result_page(cookie, payload_data)
      save_page(internal_page_html, file_name, "#{run_id}/#{iter}")
    end
  end
  
  def store
    folders = peon.list(subfolder: run_id) rescue []
    folders.each do |folder|
      create_empty_array
      files = peon.give_list(subfolder: "#{run_id}/#{folder}").sort.reject { |e| e.include? 'image'}
      files.each do |file|
        page = peon.give(subfolder: "#{run_id}/#{folder}", file: file)
        inmate_hash, tags = parser.parse(page, run_id)
        next if inmate_hash.nil?
        inmate_id = keeper.insert_data(inmate_hash, 'UtSaltLakeInmates')
        store_data(inmate_id, tags)
      end
      store_all_data
    end
    keeper.mark_delete
    keeper.finish
  end

  def create_empty_array
    @additional_info_array = []
    @alias_array = []
    @inmate_ids_array = []
    @holding_facilities_array = []
    @bonds_array = []
    @charges_array = []
  end

  def store_all_data
    keeper.store(@additional_info_array, 'UtSaltLakeInmateAdditionalInfo')
    keeper.store(@alias_array.flatten.reject(&:empty?), 'UtSaltLakeInmateAliases') unless @alias_array.empty?
    keeper.store(@inmate_ids_array, 'UtSaltLakeInmateIds')
    keeper.store(@holding_facilities_array, 'UtSaltLakeHoldingFacilities')
    keeper.store(@bonds_array.flatten.reject(&:empty?), 'UtSaltLakeBonds')
    keeper.store(@charges_array.flatten.reject(&:empty?), 'UtSaltLakeCharges')
    create_empty_array
  end

  def store_data(inmate_id, page)
    arrest_hash = parser.get_arrests(page, inmate_id, run_id)
    arrest_id = keeper.insert_data(arrest_hash, 'UtSaltLakeArrests')
    @additional_info_array << parser.get_inmate_additional_info(page, inmate_id, run_id)
    @alias_array << parser.get_alias_array(page, inmate_id, run_id)
    @inmate_ids_array << parser.get_inmates_ids(page, inmate_id, run_id)
    hold_fac_hash = parser.get_holding_facilities_addresses(page, run_id)
    hold_fac_add_id = keeper.insert_data(hold_fac_hash, 'UtSaltLakeHoldingFacilitiesAddresses')
    @holding_facilities_array << parser.get_holding_facilities(page, arrest_id, hold_fac_add_id, run_id)
    @charges_array << parser.get_charges_array(page, arrest_id, run_id)
    @bonds_array << parser.get_bonds_array(page, arrest_id, run_id)
    store_all_data if @additional_info_array.count > 100
  end

  attr_accessor :scraper, :parser, :keeper, :run_id

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end
  
end
