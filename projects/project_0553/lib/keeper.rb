# frozen_string_literal: true

require_relative '../models/deleware_arrestees_runs'
require_relative '../models/deleware_arrestees'
require_relative '../models/deleware_marks'
require_relative '../models/deleware_arrestee_aliases'
require_relative '../models/deleware_reg_information'
require_relative '../models/deleware_mugshots'
require_relative '../models/deleware_vehicles'
require_relative '../models/deleware_states'
require_relative '../models/deleware_cities'
require_relative '../models/deleware_zips'
require_relative '../models/deleware_addresses'
require_relative '../models/deleware_arrestee_address'
require_relative '../models/deleware_convictions'
require_relative '../models/deleware_agencies'
require_relative '../models/deleware_arrestees_agencies'


class Keeper
  def initialize
    @run_object = RunId.new(DelewareArresteesRuns)
    @run_id = @run_object.run_id
    @states = DEStates.pluck(:name)
    @cities = DECities.pluck(:name)
    @zip = DEZips.pluck(:code)
  end

  attr_reader :run_id

  def get_offenders()
    DelewareArrestees.pluck(:data_source_url)
  end

  def insert_arrestees(data_hash)
    DelewareArrestees.insert(data_hash)
    DelewareArrestees.last.id
  end

  def insert_marks(hash_array)
    DEMarks.insert_all(hash_array)
  end

  def insert_arrestee_aliases(hash_array)
    DEArresteeAlias.insert_all(hash_array)
  end

  def insert_reg_information(data_hash)
    DERegInformation.insert(data_hash)
  end

  def insert_mugshots(data_hash)
    DEMugshots.insert(data_hash)
  end

  def insert_vehicles(data_hash)
    DEVehicles.insert(data_hash)
  end

  def insert_add(data_hash)
    DEAdressess.insert(data_hash)
    DEAdressess.last.id
  end

  def insert_arrestee_address(data_hash)
    DEArresteeAdress.insert(data_hash)
  end

  def insert_arrestee_agency(data_hash)
    DEArresteeAgency.insert(data_hash)
  end

  def insert_convictions(data_hash)
    DEConvictions.insert(data_hash)
  end

  def insert_agency(data_hash)
    DEAgencies.insert(data_hash)
    DEAgencies.last.id
  end

  def insert_state(data_hash)
    if !@states.include? data_hash[:name]
      DEStates.insert(data_hash)
      return DEStates.last.id
    else
      return DEStates.where(:name => data_hash[:name]).pluck(:id)[0]
    end
  end

  def insert_city(data_hash)
    if !@cities.include? data_hash[:name]
      DECities.insert(data_hash)
      return DECities.last.id
    else
      return DECities.where(:name => data_hash[:name]).pluck(:id)[0]
    end
  end

  def insert_zip(data_hash)
    if !@zip.include? data_hash[:code]
      DEZips.insert(data_hash)
      return DEZips.last.id
    else
      return DEZips.where(:code => data_hash[:code]).pluck(:id)[0]
    end
  end

  def finish
    @run_object.finish
  end
end
