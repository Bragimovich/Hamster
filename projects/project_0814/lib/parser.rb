# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    super
  end

  def get_ids(json)
    json = JSON.parse(json)
    json.map { |e| e["id"] }
  end

  def get_court_hearings_hash(data, charge_id, run_id)
    hash = {}
    hash[:charge_id] = charge_id
    hash[:court_name] = data["court"]
    hash[:case_number] = data["charge_court"].split("#").last.strip
    hash = commom_hash(hash, run_id)
    hash
  end

  def get_bonds_hash(data, arrest_id, charge_id, run_id)
    hash = {}
    hash[:arrest_id] = arrest_id
    hash[:charge_id] = charge_id
    hash[:bond_category] = data["cash_only"]
    hash[:bond_amount] = data["bail"]
    hash = commom_hash(hash, run_id)
    hash
  end

  def get_charge_hash(data, arrest_id, run_id)
    hash = {}
    hash[:arrest_id] = arrest_id
    hash[:description] = data["charge_desc"]
    hash[:docket_number] = data["charge_court"].split("#").last.squish
    hash = commom_hash(hash, run_id)
    hash
  end

  def get_utah_holding_facilities(data, arrest_id, run_id)
    hash = {}
    hash[:arrest_id] = arrest_id
    hash[:planned_release_date] = getFormatedDate(data["date_in"])
    hash[:actual_release_date] = getFormatedDate(data["date_out"])
    hash = commom_hash(hash, run_id)
    hash
  end

  def get_utah_arrests(data, inmate_id, run_id)
    utah_arrests = {}
    utah_arrests[:immate_id] = inmate_id
    utah_arrests[:arrest_date] = getFormatedDate(data["arst_date"])
    utah_arrests[:booking_date] = getFormatedDate(data["date_in"])
    utah_arrests[:booking_agency] =  data["a_agency"]
    utah_arrests[:booking_number] = data["id"]
    utah_arrests[:status] = data["status"]
    utah_arrests = commom_hash(utah_arrests, run_id)
    utah_arrests
  end

  def get_inmates_hash(data, run_id)
    inmates_hash = {}
    inmates_hash[:full_name] = data["name"]
    inmates_hash[:sex] = data["sex"]
    inmates_hash[:race] = data["race"]
    inmates_hash = commom_hash(inmates_hash, run_id)
    inmates_hash
  end

  def get_additional_info(data, immate_id, run_id)
    hash = {}
    hash[:immate_id] = immate_id
    hash[:height] = data["height"]
    hash[:weight] = data["weight"]
    hash[:eye_color] = data["eyes"]
    hash[:hair_color] = data["hair"]
    hash[:age] = Date.today.year - data['person']["yob"].to_i
    inmates_hash = commom_hash(hash, run_id)
    hash
  end

  def get_inmate_ids(data, immate_id, run_id)
     hash = {}
     hash[:immate_id] = immate_id
     hash[:number] =  data["status"]
     hash = commom_hash(hash, run_id)
     hash
  end

  def get_status(data, immate_id, run_id)
    hash = {}
    hash[:inmate_id] = immate_id
    hash[:status] = data["id"]
    hash = commom_hash(hash, run_id)
    hash
  end

  private

  def commom_hash(hash, run_id)
    hash[:md5_hash] = create_md5_hash(hash)
    hash[:run_id] = run_id
    hash[:touched_run_id] = run_id
    hash[:data_source_url] = 'https://sheriff.utahcounty.gov/corrections/inmateSearch'
    hash
  end

  def getFormatedDate(date)
    date.to_date rescue nil
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
