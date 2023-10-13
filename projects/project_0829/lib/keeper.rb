require_relative '../models/wi_kenosha_inmates'
require_relative '../models/wi_kenosha_inmate_additional_info'
require_relative '../models/wi_kenosha_inmate_ids'
require_relative '../models/wi_kenosha_inmate_addresses'
require_relative '../models/wi_kenosha_mugshots'
require_relative '../models/wi_kenosha_arrests'
require_relative '../models/wi_kenosha_bonds'
require_relative '../models/wi_kenosha_charges'
require_relative '../models/wi_kenosha_holding_facilities'
require_relative '../models/wi_kenosha_inmate_statuses'
require_relative '../models/wi_kenosha_arrests_additional'
require_relative '../models/wi_kenosha_bonds_additional'
require_relative '../models/wi_kenosha_charges_additional'

class Keeper

  def get_inmate_by_md5_hash(md5_hash)
    WiKenoshaInmates.where(md5_hash:md5_hash).first
  end

  def save_inmates(inmates)
    WiKenoshaInmates.insert(inmates)
  end
  
  def get_inmate_additional_info_hash(md5_hash)
    WiKenoshaInmateAdditionalInfo.where(md5_hash:md5_hash).first
  end
  
  def save_inmate_additional_info(inmate_additional_info)
    WiKenoshaInmateAdditionalInfo.insert(inmate_additional_info)
  end

  def get_inmate_id(md5_hash)
    WiKenoshaInmateIds.where(md5_hash:md5_hash).first
  end

  def save_inmate_id(inmate_id)
    WiKenoshaInmateIds.insert(inmate_id)
  end

  def get_inmate_addresses(md5_hash)
    WiKenoshaInmateAddresses.where(md5_hash:md5_hash).first
  end

  def save_inmate_addresses(inmate_addresses)
    WiKenoshaInmateAddresses.insert(inmate_addresses)
  end

  def get_mugshot(md5_hash)
    WiKenoshaMugshots.where(md5_hash:md5_hash).first
  end

  def save_mugshots(mugshots)
    WiKenoshaMugshots.insert(mugshots)
  end

  def get_arrest(md5_hash)
    WiKenoshaArrests.where(md5_hash:md5_hash).first
  end

  def save_arrest(arrests)
    WiKenoshaArrests.insert(arrests)
  end

  def get_bond(md5_hash)
    WiKenoshaBonds.where(md5_hash:md5_hash).first
  end

  def save_bond(bonds)
    WiKenoshaBonds.insert(bonds)
  end

  def get_charge(md5_hash)
    WiKenoshaCharges.where(md5_hash:md5_hash).first
  end

  def save_charge(charges)
    WiKenoshaCharges.insert(charges)
  end

  def get_holding_facility(md5_hash)
    WiKenoshaHoldingFacilities.where(md5_hash:md5_hash).first
  end

  def save_holding_facility(facility)
    WiKenoshaHoldingFacilities.insert(facility)
  end

  def get_inmate_status(md5_hash)
    WiKenoshaInmateStatuses.where(md5_hash:md5_hash)
  end

  def save_inmate_status(inmate_status)
    WiKenoshaInmateStatuses.insert(inmate_status)
  end

  def get_arrest_additional(md5_hash)
    WiKenoshaArrestsadditional.where(md5_hash:md5_hash).first
  end

  def save_arrest_additional(arrests_additional)
    WiKenoshaArrestsadditional.insert(arrests_additional)
  end

  def get_bond_additional(md5_hash)
    WiKenoshaBondsAdditional.where(md5_hash:md5_hash).first
  end

  def save_bond_additional(bonds_additoinal)
    WiKenoshaBondsAdditional.insert(bonds_additoinal)
  end

  def get_charge_additional(md5_hash)
    WiKenoshaChargesAdditional.where(md5_hash:md5_hash).first
  end

  def save_charge_additional(charges_additional)
    WiKenoshaChargesAdditional.insert(charges_additional)
  end

  def finish_with_models(run_id)
    WiKenoshaInmates.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaInmateAdditionalInfo.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaInmateIds.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaInmateAddresses.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaMugshots.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaArrests.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaBonds.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaCharges.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaHoldingFacilities.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaInmateStatuses.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaArrestsadditional.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaBondsAdditional.where.not(touched_run_id:run_id).update(deleted:1)
    WiKenoshaChargesAdditional.where.not(touched_run_id:run_id).update(deleted:1)
  end
end
