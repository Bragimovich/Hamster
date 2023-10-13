require_relative '../models/maryland_facilities_addresses'
require_relative '../models/maryland_facilties_additional'
require_relative '../models/maryland_inmate_ids_additional'
require_relative '../models/maryland_inmates_ids'
require_relative '../models/maryland_inmates'
require_relative '../models/maryland_inmates_runs'
require_relative '../models/maryland_holding_facilities'

class Keeper

  def initialize
    @run_object = RunId.new(MaryLandRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_inmates(data_hash)
    insertion_and_foriegn_key(MaryLandInmates, data_hash)
  end

  def insert_facility_hash(data_hash)
    insertion_and_foriegn_key(MaryLandFacilitiesAddresses, data_hash)
  end

  def insert_inmate_ids(data_hash)
    insertion_and_foriegn_key(MaryLandInmateIds, data_hash)
  end

  def additional_inmate(hash)
    MaryLandInmateIdsAdditional.insert(hash)
  end

  def update_touched_run_id(inmate_md5, inmate_id_md5, inmate_additional_md5)
    touched_id_updation(MaryLandInmates, inmate_md5)
    touched_id_updation(MaryLandInmateIds, inmate_id_md5)
    touched_id_updation(MaryLandInmateIdsAdditional, inmate_additional_md5)
  end

  def facility_touched_run_id_update(facility_md5, additional_facilities_md5, holding_facility_md5)
    touched_id_updation(MaryLandFacilitiesAddresses, facility_md5)
    touched_id_updation(MaryLandFacilitiesAdditional, additional_facilities_md5)
    touched_id_updation(MaryLandHoldingFacilities, holding_facility_md5)
  end

  def insert_additional_facility(facility_addtional_hash, holding_facility_hash)
    MaryLandFacilitiesAdditional.insert(facility_addtional_hash)
    MaryLandHoldingFacilities.insert(holding_facility_hash)
  end

  def finish
    @run_object.finish
  end

  def mark_deleted
    @models = [MaryLandInmates, MaryLandInmateIds, MaryLandInmateIdsAdditional, MaryLandFacilitiesAddresses, MaryLandFacilitiesAdditional, MaryLandHoldingFacilities]
    models.each do |model|
      model.where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    end
  end

  def close_connection
    models.each do |model|
      Hamster.close_connection(model)
    end
  end

  private

  attr_reader :models

  def touched_id_updation(model, md5)
    model.where(:md5_hash => md5).update_all(:touched_run_id => run_id)
  end

  def insertion_and_foriegn_key(model, hash)
    model.insert(hash)
    model.where(:md5_hash => hash[:md5_hash]).pluck(:id)[0]
  end

end
