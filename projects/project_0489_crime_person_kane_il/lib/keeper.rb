require_relative '../models/module'
require_relative '../models/crime_il_kane_db_models'



class Keeper


  def existed_arrestees(person_id)
    IlKaneArrestees.where(id:person_id).first
  end

  def save_arrestees(arrestees)
    IlKaneArrestees.insert(arrestees)
  end

  def save_arrests(arrests)
    IlKaneArrests.insert(arrests)
  end

  def save_mugshot(arrests)
    IlKaneMugshots.insert(arrests)
  end

  def save_address(address)
    IlKaneArresteeAddresses.insert(address)
  end


  def get_arrest(booking_number)
    IlKaneArrests.where(booking_number:booking_number).last.id
  end

  def get_arrest_by_md5_hash(md5_hash)
    IlKaneArrests.where(md5_hash:md5_hash).first
  end

  def get_arrest_from_id(arrest_id)
    IlKaneArrests.where(id:arrest_id).last.arrest_date
  end

  def keep_charge(charge)
    IlKaneCharges.insert(charge)
  end

  def get_charge(md5_hash)
    IlKaneCharges.where(md5_hash:md5_hash).first
  end

  def keep_bond(bond)
    IlKaneBonds.insert(bond)
  end

  def get_bond_by_md5(md5_hash)
    IlKaneBonds.where(md5_hash:md5_hash).first
  end

  def keep_court_hearing(court_hearing)
    IlKaneCourtHearing.insert(court_hearing)
  end

  def get_court_by_md5(md5_hash)
    IlKaneCourtHearing.where(md5_hash:md5_hash).first
  end

  def keep_holding_activity(holding_activity)
    IlKaneHoldingFacilities.insert(holding_activity)
  end

  def get_ha_by_md5(md5_hash)
    IlKaneHoldingFacilities.where(md5_hash:md5_hash).first
  end

  def get_address_by_md5_hash(md5_hash)
    IlKaneArresteeAddresses.where(md5_hash:md5_hash).first
  end


  def finish_with_models(run_id)
    IlKaneArrestees.where.not(touched_run_id:run_id).update(deleted:1)
    IlKaneArrests.where.not(touched_run_id:run_id).update(deleted:1)
    IlKaneCharges.where.not(touched_run_id:run_id).update(deleted:1)
    IlKaneBonds.where.not(touched_run_id:run_id).update(deleted:1)
    IlKaneCourtHearing.where.not(touched_run_id:run_id).update(deleted:1)
    IlKaneHoldingFacilities.where.not(touched_run_id:run_id).update(deleted:1)
    IlKaneMugshots.where.not(touched_run_id:run_id).update(deleted:1)
  end



end