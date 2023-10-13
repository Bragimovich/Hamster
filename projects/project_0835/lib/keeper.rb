require_relative '../models/mi_wayne_inmates'
require_relative '../models/mi_wayne_arrests'
require_relative '../models/mi_wayne_charges'
require_relative '../models/mi_wayne_inmate_ids'
require_relative '../models/mi_wayne_holding_facilities'
require_relative '../models/mi_wayne_court_hearings'
require_relative '../models/mi_wayne_bonds'
require_relative '../models/mi_wayne_charges_and_bonds' 
class Keeper

  def get_inmate_by_md5_hash(md5_hash)
    MiWayneInmates.where(md5_hash:md5_hash).first
  end

  def save_inmates(inmates)
    MiWayneInmates.insert(inmates)
  end 

  def get_arrests(md5_hash)
    MiWayneArrest.where(md5_hash:md5_hash).first
  end

  def save_arrests(arrests)
    MiWayneArrest.insert(arrests)
  end

  def get_charge(md5_hash)
    MiWayneCharges.where(md5_hash:md5_hash).first
  end
  
  def save_charge(charge)
    MiWayneCharges.insert(charge)
  end

  def get_inmate_ids(md5_hash)
    MiWayneinmateIds.where(md5_hash:md5_hash).first
  end
  
  def save_inmate_ids(inmate_ids)
    MiWayneinmateIds.insert(inmate_ids)
  end

  def get_holding_facility(md5_hash)
    MiWayneHoldingFacilities.where(md5_hash:md5_hash).first
  end
  
  def save_holding_facility(facility)
    MiWayneHoldingFacilities.insert(facility)
  end

  def get_holding_county_court_hearings(md5_hash)
    MiWayneCourtHearings.where(md5_hash:md5_hash).first
  end
  
  def save_holding_county_court_hearings(county_court_hearings)
    MiWayneCourtHearings.insert(county_court_hearings)
  end

  def get_bonds(md5_hash)
    MiWayneBonds.where(md5_hash:md5_hash).first
  end
  
  def save_bonds(bonds)
    MiWayneBonds.insert(bonds)
  end
  
  def get_holding_charges_and_bonds(md5_hash)
    MiWayneChargesAndBonds.where(md5_hash:md5_hash).first
  end

  def save_holding_charges_and_bonds(charges_and_bonds)
    MiWayneChargesAndBonds.insert(charges_and_bonds)
  end

end