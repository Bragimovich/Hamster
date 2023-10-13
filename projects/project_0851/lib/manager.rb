# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end

  def download
    main_page_url              = "http://www.ctinmateinfo.state.ct.us/"
    scraper                    = Scraper.new
    main_page                  = scraper.fetch_page(main_page_url)
    cookie_value               = main_page.headers["set-cookie"]
    already_downloaded_folders = peon.list(subfolder: "#{keeper.run_id}") rescue []
    last_folder                = already_downloaded_folders == [] ? 'a' : already_downloaded_folders.sort.last
    (last_folder..'z').each do |last_name|
      already_downloaded_files = peon.list(subfolder: "#{keeper.run_id}/#{last_name}") rescue []
      already_downloaded_urls  = get_downloaded_urls(already_downloaded_files)
      path = "#{keeper.run_id}/#{last_name}"
      search_result_page = scraper.fetch_searched_page(last_name, cookie_value)
      save_file(search_result_page.body, "#{last_name}_outer_page", path)
      inner_links = parser.get_inner_links(search_result_page)
      (inner_links-already_downloaded_urls).each do |link|
        inner_page = scraper.fetch_inner_page(link, cookie_value)
        save_file(inner_page.body, "#{get_file_name(link)}", path)
      end
    end
    keeper.finish_download
    store if (keeper.download_status == 'finish')
  end

  def store
    inmates_array, inmate_ids_array, arrests_array, inmate_additional_info_array, holding_facilities_array, inmate_statuses_array, bonds_array, charges_array, court_hearings_array, parole_booking_dates_array = [], [], [], [], [], [], [], [], [], []
    folders = peon.list(subfolder: "#{keeper.run_id}") rescue []
    folders.each do |dir|
      files = peon.list(subfolder: "#{keeper.run_id}/#{dir}") rescue []
      outer_page, inner_pages = get_page_data(files)
      inner_pages.each do |page|
        page_content = peon.give(subfolder: "#{keeper.run_id}/#{dir}", file: page)
        data_source_url = parser.get_data_source_url(page_content)
        inmates_hash = parser.get_inmate(page_content, keeper.run_id, data_source_url)
        keeper.insert_records(inmates_hash, "CtNewHavenInmates")
        inmates_id = get_id_from_table("CtNewHavenInmates", inmates_hash["md5_hash"])
        inmate_ids_hash = parser.get_inmate_ids(page_content, inmates_id, keeper.run_id, data_source_url)
        keeper.insert_records(inmate_ids_hash, "CtNewHavenInmateIds")
        arrests_hash  = parser.get_arrests(page_content, inmates_id, keeper.run_id, data_source_url)
        keeper.insert_records(arrests_hash, "CtNewHavenArrests")
        inmate_additional_info_hash = parser.get_inmate_additional_info(page_content, inmates_id, keeper.run_id)
        keeper.insert_records(inmate_additional_info_hash, "CtNewHavenInmateAdditionalInfo")
        arrests_id = get_id_from_table("CtNewHavenArrests", arrests_hash["md5_hash"])
        holding_facilities_hash = parser.get_holding_facilities(page_content, arrests_id, keeper.run_id, data_source_url)
        keeper.insert_records(holding_facilities_hash, "CtNewHavenHoldingFacilities")
        inmate_statuses_hash = parser.get_inmate_statuses(page_content, inmates_id, keeper.run_id, data_source_url)
        keeper.insert_records(inmate_statuses_hash, "CtNewHavenInmateStatuses")
        charges_hash = parser.get_charges(page_content, arrests_id, keeper.run_id, data_source_url)
        keeper.insert_records(charges_hash, "CtNewHavenCharges")
        charges_id = get_id_from_table("CtNewHavenCharges", charges_hash["md5_hash"])
        bonds_hash = parser.get_bonds(page_content, arrests_id, charges_id, keeper.run_id, data_source_url)
        keeper.insert_records(bonds_hash, "CtNewHavenBonds")
        court_hearings_hash = parser.get_court_hearings(page_content, charges_id, keeper.run_id, data_source_url)
        keeper.insert_records(court_hearings_hash, "CtNewHavenCourtHearings")
        parole_booking_dates_hash = parser.get_parole_booking_dates(page_content, inmates_id, keeper.run_id)
        keeper.insert_records(parole_booking_dates_hash, "CtNewHavenParoleBookingDates")
        inmate_ids_array << inmate_ids_hash
        arrests_array << arrests_hash
        inmate_additional_info_array << inmate_additional_info_hash
        holding_facilities_array << holding_facilities_hash
        inmate_statuses_array << inmate_statuses_hash
        bonds_array << bonds_hash
        charges_array << charges_hash
        court_hearings_array << court_hearings_hash
        parole_booking_dates_array << parole_booking_dates_hash
      end
    end
    params = [inmates_array, inmate_ids_array, arrests_array, inmate_additional_info_array, holding_facilities_array, inmate_statuses_array, bonds_array, charges_array, court_hearings_array, parole_booking_dates_array]
    table_names = {"#{inmates_array.object_id}": "CtNewHavenInmates", "#{inmate_ids_array.object_id}": "CtNewHavenInmateIds", "#{arrests_array.object_id}": "CtNewHavenArrests", "#{inmate_additional_info_array.object_id}": "CtNewHavenInmateAdditionalInfo", "#{holding_facilities_array.object_id}": "CtNewHavenHoldingFacilities", "#{inmate_statuses_array.object_id}": "CtNewHavenInmateStatuses",  "#{bonds_array.object_id}": "CtNewHavenBonds", "#{charges_array.object_id}": "CtNewHavenCharges", "#{court_hearings_array.object_id}": "CtNewHavenCourtHearings", "#{parole_booking_dates_array.object_id}": "CtNewHavenParoleBookingDates"}
    perform_touch_run_id_funtionality(params, table_names)
    keeper.finish
    table_names.each do |table_name|
      Hamster.close_connection(table_name)
    end
  end

  private

  attr_accessor :parser, :keeper, :scraper

  def perform_touch_run_id_funtionality(params, table_names)
    if (keeper.download_status == 'finish')
      params.each do |array|
        table_name = table_names[:"#{array.object_id}"]
        md5_hashes_array = array.flatten.map{|x| x["md5_hash"]}
        keeper.update_touch_run_id(md5_hashes_array, table_name)
        keeper.delete_using_touch_id(table_name)
      end
    end
  end

  def get_file_name(link)
    link.split("id_inmt_num=").last.strip
  end

  def get_id_from_table(table_name, md5_hash)
    md5_hash_and_id = keeper.fetch_db_inserted_md5_hash_ids(table_name)
    md5_hash_and_id.map{|x| x if x.first==md5_hash}.compact.first.last
  end

  def get_downloaded_urls(already_downloaded_files)
    inner_files = already_downloaded_files.map{|x| x.split(".").first if x.include?("outer")==false}.compact
    inner_files.map{|x| "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{x}"}
  end

  def get_page_data(files)
    [files.map{|file| file if file.include?("outer")}.compact!, files.map{|file| file if file.include?("_pic")==false and file.include?("outer")==false}.compact!]
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

end
