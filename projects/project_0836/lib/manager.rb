# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
  end

  def download
    start_date = (Date.today.prev_year - 1).strftime("%m/%d/%Y")
    end_date = Date.today.strftime("%m/%d/%Y")
    alphabet_array = ('a'..'z').map(&:to_s)
    alphabet_start_index = alphabet_array.index(file_handling(alphabet_start_index, 'r', 'alphabets').last.split('_').first) rescue 0
    cookie, xisi_value = get_cookie_and_xisi
    alphabet_array[alphabet_start_index..].each do |alphabet|
      fr_value = 6
      result_page_response = scraper.get_result_page(cookie, alphabet, xisi_value, start_date, end_date)
      subfolder = "#{keeper.run_id}/#{alphabet}"
      next if (result_page_response.status == 302)
      save_page(result_page_response.body, "result_page", subfolder)
      while true
        pagination_response = scraper.get_pagination_page(cookie, fr_value, xisi_value)
        break if (pagination_response.status == 302)
        save_page(pagination_response.body, "page_#{fr_value}", subfolder)
        file_handling("#{alphabet}_#{fr_value}", 'a', 'alphabets')
        fr_value += 5
      end
      cookie, xisi_value = get_cookie_and_xisi
    end
  end

  def store
    processed_links = file_handling(processed_links, 'r', 'processed') rescue []
    outer_pages = peon.list(subfolder: "#{keeper.run_id}")
    outer_pages.each do |outer_page|
      files = peon.list(subfolder: "#{keeper.run_id}/#{outer_page}")
      files.each do |file|
        next if (processed_links.include? "#{outer_page}/#{file}")
        page_body = peon.give(subfolder: "#{keeper.run_id}/#{outer_page}/", file: file)
        parser.initialize_values(page_body, keeper.run_id)
        inmates_data_array,inmate_md5 = parser.parse_inmates_data
        db_inmate_ids = keeper.pluck_inmates_ids(inmates_data_array, PalmBeachInmates)
        keeper.update_touched_run_id(inmate_md5, PalmBeachInmates)
        inmates_id_data_array,inmate_id_md5 = parser.parse_inmates_id_data(db_inmate_ids)
        keeper.insert_records(inmates_id_data_array, PalmBeachInmatesId)
        keeper.update_touched_run_id(inmate_id_md5, PalmBeachInmatesId)
        mugshots_data_array,mugshot_md5 = parser.parse_mugshots(db_inmate_ids)
        keeper.insert_records(mugshots_data_array, PalmBeachInmatesMugshots)
        keeper.update_touched_run_id(mugshot_md5, PalmBeachInmatesMugshots)
        address_data_array,address_md5 = parser.parse_address_data(db_inmate_ids)
        keeper.insert_records(address_data_array, PalmBeachInmatesAddresses)
        keeper.update_touched_run_id(address_md5, PalmBeachInmatesAddresses)
        obts_additional_data_array,obts_md5 = parser.parse_additional_obts(db_inmate_ids)
        keeper.insert_records(obts_additional_data_array, PalmBeachInmatesAdditional)
        keeper.update_touched_run_id(obts_md5, PalmBeachInmatesAdditional)
        agency_additional_data_array,agency_md5 = parser.parse_additional_agencies(db_inmate_ids)
        keeper.insert_records(agency_additional_data_array, PalmBeachInmatesAdditional)
        keeper.update_touched_run_id(agency_md5, PalmBeachInmatesAdditional)
        arrest_data_array,arrest_md5 = parser.parse_arrests_data(db_inmate_ids)
        db_arrest_ids = keeper.pluck_arrest_ids(arrest_data_array, PalmBeachInmatesArrests)
        keeper.update_touched_run_id(arrest_md5, PalmBeachInmatesArrests)
        facility_data_array,facility_md5 = parser.parse_facility_data(db_arrest_ids)
        keeper.insert_records(facility_data_array, PalmBeachInmatesFacility)
        keeper.update_touched_run_id(facility_md5, PalmBeachInmatesFacility)
        charges_data_array,charges_md5 = parser.parse_charges_data(db_arrest_ids)
        db_charge_and_arrest_ids = keeper.pluck_charge_and_arrest_ids(charges_data_array, PalmBeachInmatesCharges)
        keeper.update_touched_run_id(charges_md5, PalmBeachInmatesCharges)
        bonds_data_array,bonds_md5 = parser.parse_bonds_data(db_charge_and_arrest_ids)
        keeper.insert_records(bonds_data_array, PalmBeachInmatesBonds)
        keeper.update_touched_run_id(bonds_md5, PalmBeachInmatesBonds)
        file_handling("#{outer_page}/#{file}", 'a', 'processed')
      end
    end
    models = [PalmBeachInmates,PalmBeachInmatesId,PalmBeachInmatesMugshots,PalmBeachInmatesAddresses,PalmBeachInmatesAdditional,PalmBeachInmatesArrests,PalmBeachInmatesFacility,PalmBeachInmatesCharges,PalmBeachInmatesBonds]
    models.each do |model|
      keeper.mark_delete(model)
    end
    keeper.finish
    FileUtils.rm_rf("#{storehouse}")
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def save_page(html, file_name, sub_folder)
    peon.put content: html, file: "#{file_name}", subfolder: sub_folder
  end

  def file_handling(content, flag, file_name)
    list = []
    File.open("#{storehouse}store/#{file_name}.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

  def get_cookie_and_xisi
    main_response = scraper.get_main_page
    xisi_value = parser.get_xisi_value(main_response)
    cookie_value = main_response.headers['set-cookie']
    cookie_values = cookie_value.split(';')
    cookie = "#{cookie_values.first}; #{cookie_values[3].split.last}"
    [cookie,xisi_value]
  end

end
