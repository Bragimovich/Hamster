require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = @keeper.run_id.to_s
  end

  def scrape
    download
    store
    FileUtils.rm_rf Dir.glob("#{storehouse}/store/#{run_id}*")
  end

  private

  def download
    files = peon.give_list(subfolder: run_id) rescue []
    outer_response = scraper.main_page
    ids = parser.get_ids(outer_response.body)
    ids.each do |id|
      next if files.include? ("#{id}.gz")
      inner_json = scraper.inner_page(id)
      save_page(inner_json.body, id.to_s, run_id)
    end
  end

  def store
    @additional_info_array = []
    @status_hash_array = []
    @inmate_ids_array = []
    @holding_facilities_array = []
    @utah_bonds_array = []
    @court_hearings_aray = []
    files = peon.give_list(subfolder: run_id) rescue []
    files.each_with_index do |file, index|
      page = peon.give(subfolder: run_id, file: file)
      page = JSON.parse(page)
      inmate_hash = parser.get_inmates_hash(page, run_id)
      store_data(inmate_hash, page, run_id)
    end
    store_all_data
    keeper.mark_delete
    keeper.finish
  end

  def store_all_data
    keeper.store(@additional_info_array, 'UtUtahInmateAdditionalInfo')
    keeper.store(@status_hash_array, 'UtUtahInmateStatuses')
    keeper.store(@inmate_ids_array, 'UtUtahInmateIds')
    keeper.store(@holding_facilities_array, 'UtUtahHoldingFacilities')
    keeper.store(@utah_bonds_array, 'UtUtahBonds')
    keeper.store(@court_hearings_aray, 'UtUtahCourtHearings')
  end

  def store_data(inmate_hash, page, run_id)
    inmate_id = keeper.insert_data(inmate_hash, 'UtUtahInmates')
    arrest_hash = parser.get_utah_arrests(page, inmate_id, run_id)
    arrest_id = keeper.insert_data(arrest_hash, 'UtUtahArrests')
    additional_info_hash = parser.get_additional_info(page, inmate_id, run_id)
    @additional_info_array << additional_info_hash
    status_hash = parser.get_status(page, inmate_id, run_id)
    @status_hash_array << status_hash
    inmate_ids_hash = parser.get_inmate_ids(page, inmate_id, run_id)
    @inmate_ids_array << inmate_ids_hash
    holding_facilities_hash = parser.get_utah_holding_facilities(page, arrest_id, run_id)
    @holding_facilities_array << holding_facilities_hash
    page["charges"].each_with_index do |page, index|
      utah_charges_hash = parser.get_charge_hash(page, arrest_id, run_id)
      charge_id = keeper.insert_data(utah_charges_hash, 'UtUtahCharges')
      utah_bonds_hash = parser.get_bonds_hash(page, arrest_id, charge_id, run_id)
      @utah_bonds_array << utah_bonds_hash
      court_hearings_hash = parser.get_court_hearings_hash(page, charge_id, run_id)
      @court_hearings_aray << court_hearings_hash
    end
  end

  attr_accessor :keeper, :parser, :scraper, :run_id

  def save_page(json, file_name, subfolder)
    peon.put content: json, file: file_name, subfolder: subfolder
  end
end
