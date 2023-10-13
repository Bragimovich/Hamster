# frozen_string_literal: true

require_relative '../models/ca_riverside_arrests_additional'
require_relative '../models/ca_riverside_arrests'
require_relative '../models/ca_riverside_bonds'
require_relative '../models/ca_riverside_charges'
require_relative '../models/ca_riverside_charges_additional'
require_relative '../models/ca_riverside_court_hearings'
require_relative '../models/ca_riverside_holding_facilities'
require_relative '../models/ca_riverside_holding_facilities_additional'
require_relative '../models/ca_riverside_inmate_additional_info'
require_relative '../models/ca_riverside_inmate_statuses'
require_relative '../models/ca_riverside_inmates_runs'
require_relative '../models/ca_riverside_inmates'


class Keeper
  def initialize
    @run_object = RunId.new(CaRiversideInmateRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def get_inmates()
    CaRiversideInmate.pluck(:data_source_url)
  end

  def insert_inmate(data_hash)
    old_record = CaRiversideInmate.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      CaRiversideInmate.insert(data_hash)
      return CaRiversideInmate.last.id
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
      return old_record.first[:id]
    else
      return old_record.first[:id]
    end
  end


  def insert_inmate_additional_info(data_hash)
    old_record = CaRiversideInmateAdditionalInfo.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      CaRiversideInmateAdditionalInfo.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def insert_inmate_statuses(data_hash)
    old_record = CaRiversideInmateStatuses.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      CaRiversideInmateStatuses.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def insert_inmate_arrests(data_hash)
    old_record = CaRiversideArrests.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      CaRiversideArrests.insert(data_hash)
      return CaRiversideArrests.last.id
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
      return old_record.first[:id]
    else
      return old_record.first[:id]
    end
  end

  def insert_inmate_arrests_additional(data_array)
    data_array.each do |data_hash|
      old_record = CaRiversideArrestsAdditional.where(data_source_url: data_hash[:data_source_url], value: data_hash[:value])
      if old_record.empty?
        CaRiversideArrestsAdditional.insert(data_hash)
      elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
        old_record.update(data_hash.except(:created_at))
      end
    end
  end

  def insert_charges(data_hash)
      CaRiversideCharges.insert(data_hash)
      record = CaRiversideCharges.find_by(md5_hash: data_hash[:md5_hash])
      return record.id if record
  end

  def insert_charges_additional(data_hash)
    CaRiversideChargesAdditional.insert(data_hash)
  end

  def insert_bonds(data_hash)
    CaRiversideBonds.insert(data_hash)
  end

  def insert_court_hearings(data_hash)
    CaRiversideCourtHearings.insert(data_hash)
  end

  def insert_holding_facilities(data_hash)
    old_record = CaRiversideHoldingsFacilities.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      CaRiversideHoldingsFacilities.insert(data_hash)
      return CaRiversideHoldingsFacilities.last.id
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
      return old_record.first[:id]
    else
      return old_record.first[:id]
    end
  end

  def insert_holding_facilities_additional(data_hash)
    old_record = CaRiversideHoldingsFacilitiesAdditional.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      CaRiversideHoldingsFacilitiesAdditional.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def finish
    @run_object.finish
  end
end
