# frozen_string_literal: true
require_relative '../lib/manager'

class Parser < Hamster::Parser

  def get_inner_links(response)
    html = parse_page(response.body)
    html.css("a").map{|x| "http://www.ctinmateinfo.state.ct.us/" + x.attr("href") if x.attr("href").include?"id_inmt_num"}.compact
  end

  def get_data_source_url(response)
    rows = get_rows(response)
    "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{get_value(rows, "Inmate Number").strip}"
  end  

  def get_inmate(response, run_id, data_source_url)
    rows = get_rows(response)
    data_hash = {}
    data_hash["full_name"]         = get_value(rows, "Inmate Name").strip
    data_hash["birthdate"]         = get_value(rows, "Date of Birth").to_date rescue nil
    data_hash["birthdate"]         = data_hash["birthdate"] == nil ? Date.strptime(get_value(rows, "Date of Birth"), '%m/%d/%Y') : data_hash["birthdate"]
    data_hash["md5_hash"]          = create_md5_hash(data_hash)
    data_hash["data_source_url"]   = data_source_url
    data_hash["run_id"]            = run_id
    data_hash["touched_run_id"]    = run_id
    data_hash
  end

  def get_inmate_ids(response, inmate_id, run_id, data_source_url)
    rows = get_rows(response)
    data_hash = {}
    data_hash["inmate_id"]         = inmate_id
    data_hash["number"]            = get_value(rows, "Inmate Number").strip
    data_hash["md5_hash"]          = create_md5_hash(data_hash)
    data_hash["data_source_url"]   = data_source_url
    data_hash["run_id"]            = run_id
    data_hash["touched_run_id"]    = run_id
    data_hash
  end

  def get_arrests(response, inmate_id, run_id, data_source_url)
    rows = get_rows(response)
    data_hash = {}
    data_hash["inmate_id"]         = inmate_id
    data_hash["arrest_date"]       = get_value(rows, "Latest Admission Date").to_date rescue nil
    data_hash["arrest_date"]       = data_hash["arrest_date"] == nil && get_value(rows, "Latest Admission Date") != "" ? Date.strptime(get_value(rows, "Latest Admission Date"), '%m/%d/%Y') : data_hash["arrest_date"]
    data_hash["status"]            = get_value(rows, "Status").strip
    data_hash["md5_hash"]          = create_md5_hash(data_hash)
    data_hash["data_source_url"]   = data_source_url
    data_hash["run_id"]            = run_id
    data_hash["touched_run_id"]    = run_id
    data_hash
  end

  def get_inmate_additional_info(response, inmate_id, run_id)
    rows = get_rows(response)
    data_hash = {}
    data_hash["inmate_id"]         = inmate_id
    data_hash["current_location"]  = get_value(rows, "Current Location").strip
    data_hash["detainer"]          = get_value(rows, "Detainer").strip
    data_hash["md5_hash"]          = create_md5_hash(data_hash)
    data_hash["run_id"]            = run_id
    data_hash["touched_run_id"]    = run_id
    data_hash
  end

  def get_holding_facilities(response, arrest_id, run_id, data_source_url)
    rows = get_rows(response)
    data_hash = {}
    data_hash["arrest_id"]              = arrest_id
    data_hash["facility"]               = get_value(rows, "Current Location").strip
    data_hash["max_release_date"]       = get_value(rows, "Maximum Release Date").include?("Not") ? get_value(rows, "Maximum Release Date") : get_value(rows, "Maximum Release Date").to_date rescue nil
    data_hash["max_release_date"]       = data_hash["max_release_date"] == nil ? Date.strptime(get_value(rows, "Maximum Release Date"), '%m/%d/%Y') : data_hash["max_release_date"]
    data_hash["planned_release_date"]   = get_value(rows, "Estimated Release Date").include?("Not") ? get_value(rows, "Estimated Release Date") : get_value(rows, "Estimated Release Date").to_date rescue nil
    data_hash["planned_release_date"]   = data_hash["planned_release_date"] == nil ? Date.strptime(get_value(rows, "Estimated Release Date"), '%m/%d/%Y') : data_hash["planned_release_date"]
    data_hash["md5_hash"]               = create_md5_hash(data_hash)
    data_hash["data_source_url"]        = data_source_url
    data_hash["run_id"]                 = run_id
    data_hash["touched_run_id"]         = run_id
    data_hash
  end

  def get_inmate_statuses(response, inmate_id, run_id, data_source_url)
    rows = get_rows(response)
    data_hash = {}
    data_hash["immate_id"]         = inmate_id
    data_hash["status"]            = get_value(rows, "Status").strip
    data_hash["md5_hash"]          = create_md5_hash(data_hash)
    data_hash["data_source_url"]   = data_source_url
    data_hash["run_id"]            = run_id
    data_hash["touched_run_id"]    = run_id
    data_hash
  end

  def get_bonds(response, arrest_id, charge_id, run_id, data_source_url)
    rows = get_rows(response)
    data_hash = {}
    data_hash["arrest_id"]         = arrest_id
    data_hash["charge_id"]         = charge_id
    data_hash["bond_amount"]       = get_value(rows, "Bond Amount").strip
    data_hash["md5_hash"]          = create_md5_hash(data_hash)
    data_hash["data_source_url"]   = data_source_url
    data_hash["run_id"]            = run_id
    data_hash["touched_run_id"]    = run_id
    data_hash
  end

  def get_charges(response, arrest_id, run_id, data_source_url)
    rows = get_rows(response)
    data_hash = {}
    data_hash["arrest_id"]         = arrest_id
    data_hash["description"]       = get_value(rows, "Controlling Offense").gsub("  ", "").strip
    data_hash["md5_hash"]          = create_md5_hash(data_hash)
    data_hash["data_source_url"]   = data_source_url
    data_hash["run_id"]            = run_id
    data_hash["touched_run_id"]    = run_id
    data_hash
  end

  def get_court_hearings(response, charge_id, run_id, data_source_url)
    rows = get_rows(response)
    data_hash = {}
    data_hash["charge_id"]              = charge_id
    data_hash["court_date"]             = get_value(rows, "Date of Sentence").include?("Not") ? get_value(rows, "Date of Sentence") : get_value(rows, "Date of Sentence").to_date rescue nil
    data_hash["court_date"]             = data_hash["court_date"] == nil ? Date.strptime(get_value(rows, "Date of Sentence"), '%m/%d/%Y') : data_hash["court_date"]
    data_hash["sentence_lenght"]        = get_value(rows, "Maximum Sentence").strip
    data_hash["md5_hash"]               = create_md5_hash(data_hash)
    data_hash["data_source_url"]        = data_source_url
    data_hash["run_id"]                 = run_id
    data_hash["touched_run_id"]         = run_id
    data_hash
  end

  def get_parole_booking_dates(response, inmate_id, run_id)
    rows = get_rows(response)
    data_hash = {}
    data_hash["inmate_id"]         = inmate_id
    special_parole_end_date        = get_value(rows, "Special Parole End Date").strip
    data_hash["date"]              = special_parole_end_date.include?("Not") ? special_parole_end_date : special_parole_end_date.to_date rescue nil
    data_hash["date"]              = data_hash["date"] == nil ? Date.strptime(special_parole_end_date, '%m/%d/%Y') : data_hash["date"]
    data_hash["md5_hash"]          = create_md5_hash(data_hash)
    data_hash["run_id"]            = run_id
    data_hash["touched_run_id"]    = run_id
    data_hash
  end

  private

  def get_rows(response)
    parse_page(response).css("tr")[2...-1]
  end

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def get_value(rows, key)
    value  = rows.map.with_index{|x,index| index if x.text.include?(key)}.compact.first == nil ? nil : rows[rows.map.with_index{|x,index| index if x.text.include?(key)}.compact.first]
    if value != nil
      value = value.text.split("#{key}").last.gsub(":","")
    end
    value
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.each_value do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
