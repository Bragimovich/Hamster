require_relative '../models/module'
require_relative '../models/il_mchenry_db_models'


class Keeper

  def existed_arrestees(full_name)
    IlMchenryArrestees.where(deleted: 0).where(full_name: full_name).first
  end

  def get_arrestees_id(full_name)
    arrestees = IlMchenryArrestees.where(deleted: 0).where(full_name: full_name).first
    arrestees[:id]
  end

  def save_arrestees(arrestees)
    IlMchenryArrestees.insert(arrestees)
  end

  def existed_arrestee_ids(number)
    IlMchenryArresteeIds.where(deleted: 0).where(number: number).first
  end

  def save_arrestee_ids(arrestee_ids)
    IlMchenryArresteeIds.insert(arrestee_ids)
  end

  def save_arrests(arrests)
    IlMchenryArrests.insert(arrests)
  end

  def get_arrests_id(md5_hash)
    arrests = IlMchenryArrests.where(deleted: 0).where(md5_hash: md5_hash).first
    arrests[:id]
  end

  def save_mugshot(arrests)
    IlMchenryMugshots.insert(arrests)
  end

  def get_arrest(booking_number)
    IlMchenryArrests.where(booking_number: booking_number).last.id
  end

  def get_arrest_by_md5_hash(md5_hash)
    IlMchenryArrests.where(md5_hash: md5_hash).first
  end

  def get_arrest_from_id(arrest_id)
    IlMchenryArrests.where(id: arrest_id).last.arrest_date
  end

  def keep_charge(charge)
    IlMchenryCharges.insert(charge)
  end

  def get_charge(description, arrest_id)
    IlMchenryCharges.where(description: description, arrest_id: arrest_id).first
  end

  def keep_bond(bond)
    IlMchenryBonds.insert(bond)
  end

  def get_bond_by_md5(md5_hash)
    IlMchenryBonds.where(md5_hash: md5_hash).first
  end

  def keep_court_hearing(court_hearing)
    IlMchenryCourtHearing.insert(court_hearing)
  end

  def get_court(court_date, number, court_room)
    IlMchenryCourtHearing.where(court_date: court_date, case_number: number, court_room: court_room).first
  end

  def keep_holding_activity(holding_activity)
    IlMchenryHoldingFacilities.insert(holding_activity)
  end

  def get_ha_by_md5(md5_hash)
    IlMchenryHoldingFacilities.where(md5_hash: md5_hash).first
  end

  def finish_with_models(run_id)
    IlMchenryArrestees.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryArresteeIds.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryArrests.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryCharges.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryBonds.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryCourtHearing.where.not(touched_run_id: run_id).update(deleted: 1)
    IlMchenryRuns.where(run_id: run_id).update(status: 'done')
  end

end
