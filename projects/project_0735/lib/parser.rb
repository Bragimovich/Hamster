class Parser < Hamster::Parser

  def parsing_html(page_html)
    Nokogiri::HTML(page_html.force_encoding('utf-8'))
  end

  def no_record_check(page)
    page.css("span.DivCountMsg").text.include? "There are no records matching the specified criteria."
  end

  def get_generator_values(page)
    event_validation     = page.css("div input")[4]["value"]
    view_state           = page.css("div input")[2]["value"]
    view_state_generator = page.css("div input")[3]["value"]
    [event_validation, view_state, view_state_generator]
  end

  def get_data(page, run_id)
    variable = 0
    check = false
    parsed_page = parsing_html(page)
    all_tables = parsed_page.css("table.JailView table")
    all_data_array = []
    (0..all_tables.count).each do |index|
      break if variable+index >= all_tables.count
      name_table = all_tables[index+variable]
      if (all_tables.count > 1) && (variable+index < all_tables.count-1)
        if all_tables[index+variable+1].text.include? "HOLDS"
          hold_table =  all_tables[index+variable+1]
          variable = variable + 1
          if all_tables[index+variable+1].text.include? "CHARGES"
            charge_table =  all_tables[index+variable+1]
            variable = variable + 1
          end
        elsif all_tables[index+variable+1].text.include? "CHARGES"
          charge_table =  all_tables[index+variable+1]
          variable = variable + 1  
        end
      end
      all_data_array << get_hash_data(name_table, charge_table, hold_table, run_id)
    end
    all_data_array
  end

  def add_md5_hash(hash)
    hash[:md5_hash] = create_md5_hash(hash)
    hash
  end

  def get_booking_ids(page)
    booking_ids_array = []
    page.css("table.JailView table tbody").each do |row|
      clean_info = row.text.split("\t").reject { |e| e.squish.empty? }
      booking_ids_array << get_value("Booking No:", clean_info)
    end
    booking_ids_array
  end

  private

  def get_hash_data(name_table, charge_table, holds_table, run_id)
    bond_array, arrest_array, inmate_array, inmate_id_array = [], [], [], []
    holding_facilities_array, court_hearings_array, charge_array = [], [], []
    holds_array = []
    unless holds_table.nil?
      holds = holds_table.text.gsub("\t",'').gsub("  ",'').split("\r\n").reject(&:empty?).last 
    end
    name                    = name_table.css("thead").text.gsub("\t",'').gsub("  ",'').split("\r\n").reject(&:empty?)
    clean_info              = name_table.css("tbody").text.split("\t").reject { |e| e.squish.empty? }
    holds_hash              = get_holds_data(holds, run_id)
    charge_data             = get_charge_data(charge_table)
    inmate_hash             = get_inmate_data(name, run_id, clean_info)
    holding_facilities_hash = get_holding_facilities_data(run_id, clean_info)
    arrest_hash             = get_arrest_data(run_id, clean_info) 
    bond_hash               = get_bond_data(run_id, clean_info)
    charge_data.each do |charge|
      arrest_charge_hash  = get_arrest_charge_data(arrest_hash, charge)
      charge_hash         = get_charge_hash(run_id, charge)
      charge_bond_hash    = get_charge_bond_data(run_id, charge)
      inmate_id_hash      = get_inmate_id_data(run_id, charge)
      court_hearings_hash = get_court_hearing(run_id, charge)
      bond_array << charge_bond_hash
      inmate_id_array << inmate_id_hash
      court_hearings_array << court_hearings_hash
      arrest_array << arrest_charge_hash
      charge_array << charge_hash
    end
    arrest_array << arrest_hash if charge_data.empty?
    bond_array << bond_hash
    inmate_array << inmate_hash
    holding_facilities_array << holding_facilities_hash
    holds_array << holds_hash
    [bond_array, arrest_array, inmate_array, holding_facilities_array, court_hearings_array, inmate_id_array, charge_array, holds_array]
  end

  def get_court_hearing(run_id, charge)
    court_hearings_hash = {}
    court_hearings_hash[:run_id]    = run_id
    court_hearings_hash[:case_type] = charge[:case_type]
    court_hearings_hash             = mark_empty_as_nil(court_hearings_hash)
    court_hearings_hash[:touched_run_id]    = run_id
    court_hearings_hash
  end

  def get_inmate_id_data(run_id, charge)
    inmate_id_hash            = {}
    inmate_id_hash[:run_id]   = run_id
    inmate_id_hash[:type]     = charge[:type]
    inmate_id_hash            = mark_empty_as_nil(inmate_id_hash)
    inmate_id_hash[:touched_run_id]    = run_id
    inmate_id_hash
  end

  def get_inmate_data(name, run_id, clean_info)
    inmate_hash             = {}
    inmate_hash[:run_id]    = run_id
    inmate_hash[:full_name] = name[0]
    inmate_hash[:sex]       = name[2]
    inmate_hash[:first_name], inmate_hash[:last_name], inmate_hash[:middle_name] = name_split(name[0])
    inmate_hash[:age_as_of_date]    = get_value("Age On Booking Date", clean_info)
    inmate_hash[:visitation_status] = get_value("Visitation", clean_info)
    inmate_hash                     = mark_empty_as_nil(inmate_hash)
    inmate_hash[:md5_hash]          = create_md5_hash(inmate_hash)
    inmate_hash[:touched_run_id]    = run_id
    inmate_hash
  end

  def get_holding_facilities_data(run_id, clean_info)
    holding_facilities_hash = {}
    holding_facilities_hash = {}
    holding_facilities_hash[:run_id]         = run_id
    holding_facilities_hash[:full_address]   = get_value("CELL Assigned:", clean_info)
    holding_facilities_hash[:street_address] = get_value("Address Given", clean_info)
    address = holding_facilities_hash[:street_address].split(' ') rescue nil
    city, state, zip = get_address_info(address)
    holding_facilities_hash[:city]      = city
    holding_facilities_hash[:state]     = state
    holding_facilities_hash[:zip]       = zip
    holding_facilities_hash             = mark_empty_as_nil(holding_facilities_hash)
    holding_facilities_hash[:md5_hash]  = create_md5_hash(holding_facilities_hash)
    holding_facilities_hash[:touched_run_id]    = run_id
    holding_facilities_hash
  end

  def get_holds_data(holds, run_id)
    holds_hash  = {}
    holds_hash[:run_id]     = run_id
    holds_hash[:facility]   = holds
    holds_hash              = mark_empty_as_nil(holds_hash)
    holds_hash[:touched_run_id]    = run_id
    holds_hash
  end

  def get_arrest_data(run_id, clean_info)
    arrest_hash                         = {}
    arrest_hash[:run_id]                = run_id
    arrest_hash[:status]                = get_value("Status", clean_info)
    arrest_hash[:booking_number]        = get_value("Booking No:", clean_info)
    arrest_hash[:booking_date]          = DateTime.strptime(get_value("Booking Date", clean_info), '%m/%d/%Y').to_date
    arrest_hash[:actual_booking_number] = get_value("MniNo", clean_info)
    arrest_hash                         = mark_empty_as_nil(arrest_hash)
    arrest_hash[:md5_hash]              = create_md5_hash(arrest_hash)
    arrest_hash[:touched_run_id]    = run_id
    arrest_hash
  end

  def get_bond_data(run_id, clean_info)
    bond_hash                           = {}
    bond_hash[:run_id]                  = run_id
    bond_hash[:bond_amount]             = get_value("Bond Amount", clean_info)
    bond_hash[:bond_fees]               = get_value("Cash Only:", clean_info)
    bond_hash                           = mark_empty_as_nil(bond_hash)
    bond_hash[:touched_run_id]    = run_id
    bond_hash
  end

  def get_arrest_charge_data(arrest_hash, charge)
    arrest_charge_hash              = {}
    arrest_charge_hash              = arrest_hash
    arrest_charge_hash[:officer]    = charge[:officer]
    arrest_charge_hash              = mark_empty_as_nil(arrest_charge_hash)
    arrest_charge_hash[:md5_hash]   = create_md5_hash(arrest_charge_hash)
    arrest_charge_hash
  end

  def get_charge_hash(run_id, charge)
    charge_hash                     = {}
    charge_hash[:description]       = charge[:name].include?("\r\n") ? nil : charge[:name]
    charge_hash[:number]            = charge[:number]
    charge_hash[:run_id]            = run_id
    charge_hash                     = mark_empty_as_nil(charge_hash)
    charge_hash[:md5_hash]          = create_md5_hash(charge_hash)
    charge_hash[:touched_run_id]    = run_id
    charge_hash
  end

  def get_charge_bond_data(run_id, charge)
    charge_bond_hash                = {}
    charge_bond_hash[:run_id]       = run_id
    charge_bond_hash[:bond_amount]  = charge[:bond_amount]
    charge_bond_hash[:bond_type]    = charge[:bond_type]
    charge_bond_hash[:bond_fees]    = charge[:bond_fees]
    charge_bond_hash                = mark_empty_as_nil(charge_bond_hash)
    charge_bond_hash[:touched_run_id]    = run_id
    charge_bond_hash
  end

  def get_address_info(address)
    city, state, zip = nil
    unless (address.nil?) || (address.count == 1)
      city, state, zip = get_address_values(address)
    end
    [city, state, zip]
  end

  def get_address_values(address)
    city, state, zip = nil
    if address[-1].match /^(?=.*\d)[a-zA-Z\d]+$/
      zip   = address[-1]
      if address[-2].length > 2
        city  = address[-2]
        if (address[-3].length == 2) && (address[-3].match /\A[a-zA-Z]+\z/)
          state = address[-3]
        end
      else
        city  = address[-3]
        state = address[-2]
      end
    else
      if address[-1].length > 2
        city  = address[-1]
        if (address[-2].length == 2) && (address[-2].match /\A[a-zA-Z]+\z/)
          state = address[-2]
        end
      else
        city  = address[-2]
        state = address[-1]
      end
    end
    [city, state, zip]
  end

  def name_split(name)
    last_name,first_name,middle_name = nil
    return [] if name == nil or name == ','
    last_name,first_name = name.split(",")
    if first_name.split(" ").count == 2
      first_name,middle_name = first_name.split(" ")
    else last_name.split(" ").count == 2
      last_name,middle_name = last_name.split(" ")
    end
    [first_name.strip, last_name, middle_name]
  end

  def get_charge_data(charges)
    charge_array = []
    return {}  if charges.nil?
    charges.css("tr").each do |charge|
      next if charge.text.strip == "CHARGES"
      next if charge.text.include? "Warrant Number / Citation Number"
      charge                  = charge.css("td")
      next if charge.count == 1
      charge_hash = {}
      charge_hash[:case_type] = get_charge(1, charge)
      charge_hash[:name]      = get_charge(3, charge)
      charge_hash[:type]      = get_charge(5, charge)
      charge_hash[:bond_amount] = get_charge(6, charge)
      charge_hash[:bond_type]   = get_charge(7, charge)
      charge_hash[:bond_fees]   = get_charge(8, charge)
      charge_hash[:officer]     = get_charge(9, charge)
      charge_hash[:number]      = get_charge(10, charge)
      charge_array << charge_hash
    end
    charge_array
  end

  def get_charge(index, charge)
    charge[index].text.strip
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "N/A") ? nil : value}
  end

  def get_value(key, data_array)
    data = data_array.select{|a| a.include? key}[0]
    return nil if data.nil?
    if data.squish[-1].include?":"
      index = data_array.index data
      data = data_array[index+1]
      data = nil  if (key == "CELL Assigned:" )&& (data.include? "Address")
    else
      data = data.split(":").last
    end
    data.squish! unless data.nil?
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
