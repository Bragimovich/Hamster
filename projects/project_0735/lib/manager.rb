require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper  = Scraper.new
    @run_id = keeper.run_id.to_s
  end

  def run
    keeper.download_status == 'finish' ? store : download
  end
  
  def download
    already_inserted_booking = keeper.get_booking_number
    main_page = scraper.connect_main_page
    page = parser.parsing_html(main_page.body)
    generator_values = parser.get_generator_values(page)
    already_downloaded_files = peon.list(subfolder: "#{run_id}").sort rescue []
    alphabet = ('aa'..'zz').to_a
    alphabet.each do |first_name|
      alphabet.each do |last_name|
        file_name = "#{first_name}_#{last_name}"
        next if already_downloaded_files.include? "#{file_name}.gz"

        data_page = scraper.connect_page(generator_values, last_name, first_name)
        page = parser.parsing_html(data_page.body)
        next if (parser.no_record_check(page))

        booking_ids_array = parser.get_booking_ids(page)
        next if booking_ids_array.reject{|a|already_inserted_booking.include? a}.empty?

        save_file(run_id, data_page.body, file_name)
      end
    end
    keeper.finish_download
    store if keeper.download_status == "finish"
  end

  def store
    files = peon.list(subfolder: "#{run_id}")
    already_inserted_booking = keeper.get_booking_number

    all_data_array = []
    holding_facilities_array = []
    md5_hash_array = []
    files.each do |file|
      page = peon.give(file: file ,subfolder: run_id)
      all_data_array = parser.get_data(page, run_id)
      all_data_array.each do |data_array|
        md5_hash_array << data_array[1][0][:md5_hash]
        next if already_inserted_booking.include? data_array[1][0][:booking_number]

        insert_all_records(data_array)
      end
    end
    if keeper.download_status == 'finish'
      keeper.update_touch_run_id(md5_hash_array)
      keeper.finish
    end
  end

  private

  attr_accessor :keeper, :parser , :scraper , :run_id

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end

  def insert_all_records(data_array)
    inmate_id    = insert_record("inmates", data_array[2][0])
    arrest_array = add_foriegn_key("immate_id", inmate_id, data_array[1])
    arrest_ids   = insert_records("arrest" , arrest_array)
    charge_array = add_multiple_foriegn_key("arrest_id", arrest_ids, data_array[6])
    charge_ids   = insert_records("charges" , charge_array)
    bond_array   = add_multiple_foriegn_key("arrest_id", arrest_ids, data_array[0])
    bond_array   = add_multiple_foriegn_key("charge_id", charge_ids, bond_array)
    bond_array   = add_md5(bond_array)
    court_hearings_array = add_multiple_foriegn_key("charge_id", charge_ids,  data_array[4])
    court_hearings_array = add_md5(court_hearings_array)
    holding_address_ids  = insert_record("holding_address", data_array[3][0])
    inmate_id_array      = add_foriegn_key("immate_id", inmate_id, data_array[5])
    holds_array = add_foriegn_key("holding_facilities_addresse_id", holding_address_ids, data_array[7])
    holds_array = add_multiple_foriegn_key("arrest_id", arrest_ids, holds_array)
    holds_array = add_md5(holds_array)
    store_record("inmates_ids", inmate_id_array)
    store_record("court", court_hearings_array)
    store_record("bonds", bond_array)
    store_record("holding_facilities", holds_array)
  end

  def add_foriegn_key(key, value, data_array)
    data_array.each do |data|
      data[key] = value
    end
  end

  def insert_record(key, data)
    keeper.insert_return_id(key, data)
  end

  def add_multiple_foriegn_key(key, ids, data_array)
    data_array.each_with_index do |data, index|
      data[key] = ids[index]
    end
  end

  def add_md5(data_array)
    data_array.each do |hash|
      hash = parser.add_md5_hash(hash)
    end
    data_array
  end

  def store_record(key, data)
    keeper.insert_record(key ,data)
  end

  def insert_records(key, data_array)
    id_array = []
    data_array.each do |data|
      id = keeper.insert_return_id(key, data)
      id_array << id 
    end
    id_array
  end

end
