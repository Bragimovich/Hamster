# frozen_string_literal: true

class Parser < Hamster::Parser
  BASE_URL = "https://www.dupagesheriff.org/inmateSearch/"

  def parse_data(data)
    dope_county = {}
    dope_county["inmates"] = get_il_dupage_inmates(data)
    dope_county["inmate_ids"] = get_il_dupage_inmate_ids(data)
    dope_county["mugshots"] = get_il_dupage_mugshots(data)
    dope_county["arrest"] = get_il_dupage_arrests(data)
    dope_county["bonds"] = get_il_dupage_bonds(data)
    dope_county["charges"] = get_il_dupage_charges(data)
    dope_county["court_hearings"] = get_il_dupage_court_hearings(data)
    dope_county["additional_info"] = get_il_dupage_inmate_additional_info(data)
    dope_county["hold_info"] = get_hold_info(data)
    dope_county
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
  
  private
  def parse_from_nokogiri(data, key_value, loop_data = true)
    response = Nokogiri::HTML(data)
    return response.css('text()').select{|e| e.text.include? key_value }.first.text.split(key_value).last.squish rescue nil unless loop_data

    information_idx = extract_data(response, "Information:")
    bond_info_idx = extract_data(response, "Bond Info:")
    charge_info_idx = extract_data(response, "Charge Info:")
    hold_info_idx = extract_data(response, "Hold Info:")
    ending_idx = extract_data(response, "Bonding and Visitation Information")
  
    hash_range = {
      "information_idx" => bond_info_idx,
      "bond_info_idx" => charge_info_idx,
      "charge_info_idx" => hold_info_idx,
      "hold_info_idx" => ending_idx
    }
    
    end_value = hash_range[key_value]
    extract_val(key_value, end_value, response, information_idx, bond_info_idx, charge_info_idx, hold_info_idx)
  end

  def extract_data(response, text_search)
    response.css('text()').index { |a| a.text.include?(text_search) }
  end

  def extract_val(key_value, end_idx, response, information_idx, bond_info_idx, charge_info_idx, hold_info_idx)
    case key_value
    when "information_idx"
      [information_idx, end_idx, response]
    when "bond_info_idx"
      [bond_info_idx, end_idx, response]
    when "charge_info_idx"
      [charge_info_idx, end_idx, response]
    when "hold_info_idx"
      [hold_info_idx, end_idx, response]
    end
  end
  
  def get_il_dupage_inmates(data)
    inmates = {}
    inmates["full_name"] = data["title"].split(' ')[0..-3].join(" ").strip
    inmates["race"] = parse_from_nokogiri(data["content"], "Race:", false)
    inmates["data_source_url"] = get_link(data)
    inmates
  end

  def get_il_dupage_inmate_ids(data)
    inmate_ids = {}
    inmate_ids["number"] = data["offenderID"].to_s.empty? ? data["title"].split('-')[-1].strip : data["offenderID"]
    inmate_ids["data_source_url"] = get_link(data)
    inmate_ids

  end

  def get_il_dupage_mugshots(data)
    mugshots = {}
    mugshots['original_link'] = data["images"].length > 0 ? data["images"][0]["small"] : nil
    unless mugshots['original_link'].nil?
      mugshots["data_source_url"] = get_link(data)
    end
    mugshots
  end

  def get_il_dupage_arrests(data)
    arrest = {}
    booking_date = parse_from_nokogiri(data["content"], "Booking Date", false)
    unless booking_date.empty?
      arrest['booking_date'] = get_booking_data(booking_date)
      arrest["data_source_url"] = get_link(data)
    end
    arrest
  end

  def get_booking_data(booking_date)
    format = "%m/%d/%Y"
    booking_date = booking_date.gsub(":","").strip      
    output_format = "%Y-%m-%d"
    final_date = Date.strptime(booking_date.strip, format).strftime(output_format)
    final_date
  end

  def get_il_dupage_bonds(data)
    bond_info = []
    response_check = parse_from_nokogiri(data["content"], "bond_info_idx")
    unless response_check.nil?
      start_index, end_index, response = response_check
      bond = get_loop_data(start_index + 1, end_index - 1, response, 2)
      bond_info = bond.map { |hash| { "bond_number" => hash["Case Number"], "bond_amount" => hash["Bond Amount"] } }
      bond_info = bond_info.map { |hash| hash.merge("bond_amount" => hash["bond_amount"].delete('$')) } 
      data_url = get_link(data)
      bond_info = bond_info.map { |hash| hash.merge("data_source_url" => data_url) }
    end
    bond_info
  end

  def get_il_dupage_charges(data)
    charges_data = {}
    charges = get_charge_info(data["content"])
    unless charges.empty?
      charges_required = charges.map { |hash| hash.slice("Case Number", "Charge Description", "Count") }
      charges_data = charges_required.map { |hash| { "docket_number" => hash["Case Number"], "description" => hash["Charge Description"], "counts" => hash["Count"] } }
      data_url = get_link(data)
      charges_data = charges_data.map { |hash| hash.merge("data_source_url" => data_url) }
    end
    charges_data
  end

  def get_il_dupage_court_hearings(data)
    courts_data = {}
    courts = get_charge_info(data["content"])
    unless courts.empty?
      courts_required = courts.map { |hash| hash.slice("Case Number", "Next Court Date") }
      courts_data = courts_required.map { |hash| { "case_number" => hash["Case Number"], "next_court_date" => hash["Next Court Date"] } }
      data_url = get_link(data)
      input_format = "%m/%d/%Y"
      output_format = "%Y-%m-%d"
      courts_data = courts_data.map! { |hash| hash.merge("next_court_date" => begin Date.strptime(hash["next_court_date"], input_format).strftime(output_format) rescue "" end) }
      data_url = get_link(data)
      courts_data = courts_data.map { |hash| hash.merge("data_source_url" => data_url) }
    end
    courts_data
  end

  def get_charge_info(data)
    charge_info = {}
    response_check = parse_from_nokogiri(data, "charge_info_idx")
    unless response_check[1] - response_check[0] == 1
      start_index, end_index, response = parse_from_nokogiri(data, "charge_info_idx")
      charge_info = get_loop_data(start_index + 1, end_index - 1, response, 4)
    end
    charge_info
  end

  def get_il_dupage_inmate_additional_info(data)
    additional_info = {}
    additional_info["height"] = get_additional_details(data["content"], "Height:")
    additional_info["weight"] = get_additional_details(data["content"], "Weight:")
    additional_info["hair_color"] = get_additional_details(data["content"], "Hair Color:")
    additional_info["eye_color"] = get_additional_details(data["content"], "Eye Color:")
    additional_info
  end

  def get_additional_details(data, text_search)
    parse_from_nokogiri(data, text_search, false).empty? ? nil : parse_from_nokogiri(data, text_search, false)
  end

  def get_loop_data(start_index, end_index, response, loop_time)
    loop_data = {}
    loop_array = []
    count = 0
    (start_index..end_index).each do |idx|
      if count % loop_time == 0 and count != 0
        loop_array << loop_data
        loop_data = {}
      end
      special_case = response.css('text()')[idx].text
      if special_case.include?("Charge Description") && special_case.include?("Next Court Date")
        loop_data["Charge Description"] = special_case.match(/Charge Description: (.*?)(?=Next Court Date)/)&.captures&.first&.strip
        loop_data["Next Court Date"] = special_case.match(/Next Court Date: (\d{2}\/\d{2}\/\d{4})/)&.captures&.first&.strip
        loop_array << loop_data
        loop_data = {}
        count = 0
      else
        key, value = response.css('text()')[idx].text.split(":")
        loop_data[key.strip] = value.strip
        count += 1        
      end
    end
    unless loop_data.empty?
      loop_array << loop_data
    end
    loop_array
  end

  def get_hold_info(data)
    hold_info = {}
    response_check = parse_from_nokogiri(data["content"], "hold_info_idx")
    unless response_check[1] - response_check[0] == 1
      start_index, end_index, response = response_check
      hold_info_data = get_loop_data(start_index + 1, end_index - 1, response, 2)
      hold_info = hold_info_data.map { |hash| { "agency_name" => hash["Agency Name"], "bond_amount" => hash["Bond Amount"] } }
      hold_info = hold_info.map { |hash| hash.merge("bond_amount" => hash["bond_amount"].delete('$')) } 
      data_url = get_link(data)
      hold_info = hold_info.map { |hash| hash.merge("data_source_url" => data_url) }
    end
    hold_info
  end

  def get_link(data)
    BASE_URL + data["_id"].first[-1]
  end
  
end
