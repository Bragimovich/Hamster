# frozen_string_literal: true

class KeeperWf

  def existed_arrestees(full_name)
    IlWoodfordArrestees.where(deleted:0).where(full_name:full_name).first
  end

  def save_arrestees(arrestees)
    IlWoodfordArrestees.insert(arrestees)
  end

  def save_arrests(arrests)
    IlWoodfordArrests.insert(arrests)
  end

  def save_mugshot(arrests)
    IlWoodfordMugshots.insert(arrests)
  end


  def get_arrest(booking_number)
    IlWoodfordArrests.where(booking_number:booking_number).last.id
  end

  def get_arrest_by_md5_hash(md5_hash)
    IlWoodfordArrests.where(md5_hash:md5_hash).first
  end

  def get_arrest_from_id(arrest_id)
    IlWoodfordArrests.where(id:arrest_id).last.arrest_date
  end

  def keep_charge(charge)
    IlWoodfordCharges.insert(charge)
  end


  def get_charge(md5_hash)
    IlWoodfordCharges.where(md5_hash:md5_hash).first
  end

  def keep_bond(bond)
    IlWoodfordBonds.insert(bond)
  end

  def get_bond_by_md5(md5_hash)
    IlWoodfordBonds.where(md5_hash:md5_hash).first
  end

  def keep_court_hearing(court_hearing)
    IlWoodfordCourtHearing.insert(court_hearing)
  end

  def get_court_by_md5(md5_hash)
    IlWoodfordCourtHearing.where(md5_hash:md5_hash).first
  end

  def keep_holding_activity(holding_activity)
    IlWoodfordHoldingFacilities.insert(holding_activity)
  end

  def get_ha_by_md5(md5_hash)
    IlWoodfordHoldingFacilities.where(md5_hash:md5_hash).first
  end

  def mark_deleted_arrests_released(run_id)
    IlWoodfordArrests.where('release_date is null').where.not(touched_run_id:run_id).update(deleted:1)
  end

  def mark_deleted_arrests(run_id, arrestee_id)
    IlWoodfordArrests.where(arrestee_id: arrestee_id).where.not(touched_run_id:run_id).update(deleted:1)
  end

  def mark_deleted_charges(run_id, arrest_id)
    IlWoodfordCharges.where(arrest_id: arrest_id).where.not(touched_run_id:run_id).update(deleted:1)
  end

  def mark_deleted_bonds(run_id, arrest_id)
    IlWoodfordBonds.where(arrest_id: arrest_id).where.not(touched_run_id:run_id).update(deleted:1)
  end

  def mark_deleted_courts(run_id, arrest_id)
    IlWoodfordCourtHearing.where(arrest_id: arrest_id).where.not(touched_run_id:run_id).update(deleted:1)
  end


  def released_booking_ids(booking_ids)
    IlWoodfordArrests.where(booking_number:booking_ids).where('release_date is not null').map{|row| row.booking_number}
  end
end