require_relative '../models/westchester_new_york_arrests'
require_relative '../models/westchester_new_york_bonds'
require_relative '../models/westchester_new_york_charges'
require_relative '../models/westchester_new_york_court_hearings'
require_relative '../models/westchester_new_york_holding_facilities'
require_relative '../models/westchester_new_york_inmate_aliases'
require_relative '../models/westchester_new_york_inmate_ids'
require_relative '../models/westchester_new_york_inmates'
require_relative '../models/westchester_new_york_inmate_runs'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(WestchesterNewYorkInmateRuns)
    @run_id = @run_object.run_id
  end

  def westchester_new_york_arrests(row, booking_number)
    westchester_new_york_arrests = {
      immate_id: nil,
      status: row[:status],
      officer: nil,
      arrest_date: row[:booking_date],
      booking_date: nil,
      booking_agency: nil,
      booking_agency_type: nil,
      booking_agency_subtype: nil,
      booking_number: booking_number,
      actual_booking_number: nil,
      data_source_url: 'https://correction.westchestergov.com/westchester-inmate-search',
      run_id: @run_id,
      touched_run_id: @run_id
    }
    md5 = MD5Hash.new(columns:%i[immate_id status officer arrest_date booking_date booking_agency booking_agency_type booking_agency_subtype booking_number actual_booking_number data_source_url])
    md5_westchester_new_york_arrests = {
      md5_hash: create_md5_hash(westchester_new_york_arrests, md5)
    }
    westchester_new_york_arrests.merge!(md5_westchester_new_york_arrests)
    WestchesterNewYorkArrests.insert(westchester_new_york_arrests)
  end

  def westchester_new_york_bonds(row)
    westchester_new_york_bonds = {
      arrest_id: nil,
      charge_id: nil,
      bond_category: nil,
      bond_number: nil,
      bond_type: nil,
      bond_amount: row[:bond_amount],
      paid: nil,
      bond_fees: nil,
      paid_status: nil,
      made_bond_release_date: nil,
      made_bond_release_time: nil,
      data_source_url: 'https://correction.westchestergov.com/westchester-inmate-search',
      run_id: @run_id,
      touched_run_id: @run_id
    }
    md5 = MD5Hash.new(columns:%i[arrest_id charge_id bond_category bond_number bond_type bond_amount paid bond_fees paid_status made_bond_release_date made_bond_release_time data_source_url])
    md5_westchester_new_york_bonds = {
      md5_hash: create_md5_hash(westchester_new_york_bonds, md5)
    }
    westchester_new_york_bonds.merge!(md5_westchester_new_york_bonds)
    WestchesterNewYorkBonds.insert(westchester_new_york_bonds)
  end

  def westchester_new_york_charges(row)
    westchester_new_york_charges = {
      arrest_id: nil,
      number: nil,
      name: row[:name],
      disposition: nil,
      disposition_date: nil,
      description: nil,
      offense_type: nil,
      offense_date: nil,
      offense_time: nil,
      attempt_or_commit: nil,
      docket_number: nil,
      crime_class: nil,
      acs: nil,
      counts: nil,
      data_source_url: 'https://correction.westchestergov.com/westchester-inmate-search',
      run_id: @run_id,
      touched_run_id: @run_id
    }
    md5 = MD5Hash.new(columns:%i[arrest_id number name disposition disposition_date description offense_type offense_date offense_time attempt_or_commit docket_number crime_class acs counts data_source_url])
    md5_westchester_new_york_charges = {
      md5_hash: create_md5_hash(westchester_new_york_charges, md5)
    }
    westchester_new_york_charges.merge!(md5_westchester_new_york_charges)
    WestchesterNewYorkCharges.insert(westchester_new_york_charges)
  end

  def westchester_new_york_court_hearings(row)
    westchester_new_york_court_hearings = {
      charge_id: nil,
      court_address_id: nil,
      court_name: row[:court_name],
      court_date: row[:court_date],
      court_time: nil,
      next_court_date: row[:next_court_date],
      next_court_time: nil,
      court_type: row[:court_type],
      court_room: nil,
      case_number: nil,
      case_type: row[:case],
      sentence_lenght: nil,
      sentence_type: nil,
      min_release_date: nil,
      max_release_date: nil,
      set_by: nil,
      data_source_url: 'https://correction.westchestergov.com/westchester-inmate-search',
      run_id: @run_id,
      touched_run_id: @run_id
    }
    md5 = MD5Hash.new(columns:%i[charge_id court_address_id court_name court_date court_time next_court_date next_court_time court_type court_room case_number case_type sentence_lenght sentence_type min_release_date max_release_date set_by data_source_url])
    md5_westchester_new_york_court_hearings = {
      md5_hash: create_md5_hash(westchester_new_york_court_hearings, md5)
    }
    westchester_new_york_court_hearings.merge!(md5_westchester_new_york_court_hearings)
    WestchesterNewYorkCourtHearings.insert(westchester_new_york_court_hearings)
  end

  def westchester_new_york_holding_facilities(row)
    westchester_new_york_holding_facilities = {
      arrest_id: nil,
      holding_facilities_addresse_id: nil,
      facility: nil,
      facility_type: nil,
      facility_subtype: nil,
      start_date: nil,
      planned_release_date: row[:planned_release_date],
      release_date: row[:release_date],
      actual_release_date: nil,
      max_release_date: nil,
      total_time: nil,
      data_source_url: 'https://correction.westchestergov.com/westchester-inmate-search',
      run_id: @run_id,
      touched_run_id: @run_id
    }
    md5 = MD5Hash.new(columns:%i[arrest_id holding_facilities_addresse_id facility facility_type facility_subtype start_date planned_release_date release_date actual_release_date max_release_date total_time data_source_url])
    md5_westchester_new_york_holding_facilities = {
      md5_hash: create_md5_hash(westchester_new_york_holding_facilities, md5)
    }
    westchester_new_york_holding_facilities.merge!(md5_westchester_new_york_holding_facilities)
    WestchesterNewYorkHoldingFacilities.insert(westchester_new_york_holding_facilities)
  end

  def westchester_new_york_inmate_aliases(row)
    westchester_new_york_inmate_aliases = {
      immate_id: nil,
      full_name: row[:full_name],
      first_name: row[:first_name],
      middle_name: row[:middle_name],
      last_name: row[:last_name],
      suffix: nil,
      data_source_url: 'https://correction.westchestergov.com/westchester-inmate-search',
      run_id: @run_id,
      touched_run_id: @run_id
    }
    md5 = MD5Hash.new(columns:%i[immate_id full_name first_name middle_name last_name suffix data_source_url])
    md5_westchester_new_york_inmate_aliases = {
      md5_hash: create_md5_hash(westchester_new_york_inmate_aliases, md5)
    }
    westchester_new_york_inmate_aliases.merge!(md5_westchester_new_york_inmate_aliases)
    WestchesterNewYorkInmateAliases.insert(westchester_new_york_inmate_aliases)
  end

  def westchester_new_york_inmate_ids(row)
    westchester_new_york_inmate_ids = {
      immate_id: nil,
      number: row[:number],
      type: nil,
      date_from: nil,
      date_to: nil,
      data_source_url: 'https://correction.westchestergov.com/westchester-inmate-search',
      run_id: @run_id,
      touched_run_id: @run_id
    }
    md5 = MD5Hash.new(columns:%i[immate_id number type date_from date_to data_source_url])
    md5_westchester_new_york_inmate_ids = {
      md5_hash: create_md5_hash(westchester_new_york_inmate_ids, md5)
    }
    westchester_new_york_inmate_ids.merge!(md5_westchester_new_york_inmate_ids)
    WestchesterNewYorkInmateIds.insert(westchester_new_york_inmate_ids)
  end

  def westchester_new_york_inmates(row)
    westchester_new_york_inmates = {
      full_name: row[:full_name],
      first_name: row[:first_name],
      middle_name: row[:middle_name],
      last_name: row[:last_name],
      suffix: nil,
      birthdate: row[:birth_date],
      date_of_death: nil,
      age: row[:age],
      sex: nil,
      race: nil,
      data_source_url: 'https://correction.westchestergov.com/westchester-inmate-search',
      run_id: @run_id,
      touched_run_id: @run_id
    }
    md5 = MD5Hash.new(columns:%i[full_name first_name middle_name last_name suffix birthdate date_of_death age sex race data_source_url])
    md5_westchester_new_york_inmates = {
      md5_hash: create_md5_hash(westchester_new_york_inmates, md5)
    }
    westchester_new_york_inmates.merge!(md5_westchester_new_york_inmates)
    WestchesterNewYorkInmates.insert(westchester_new_york_inmates)
  end

  def parse_data(inmate_info_hash, booking_number)		
    inmate_info_hash[0]['inmate_table'].each do |row|
      store_table_data(row)			
    end

    inmate_info_hash[0]['inmate_booking'].each do |row, booking_number|
      store_inmate_booking(row, booking_number)
    end

    inmate_info_hash[0]['inmate_details'].each do |row|
      store_inmate_details(row)
    end
  end

  def store_table_data(row)
    if row[:alias].empty?
      westchester_new_york_inmates(row)
      westchester_new_york_inmate_ids(row)
    else
      westchester_new_york_inmate_aliases(row)
      westchester_new_york_inmate_ids(row)
    end
  end

  def store_inmate_booking(row, booking_number)
    westchester_new_york_arrests(row, booking_number)
    westchester_new_york_holding_facilities(row)
    westchester_new_york_court_hearings(row)
  end

  def store_inmate_details(row)
    westchester_new_york_court_hearings(row)
    westchester_new_york_holding_facilities(row)
    westchester_new_york_bonds(row)
    westchester_new_york_charges(row)
  end

  def create_md5_hash(hash, md5)
    md5.generate(hash)
    md5.hash
  end

  def finish
    @run_object.finish
  end
end
