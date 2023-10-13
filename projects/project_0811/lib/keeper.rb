# frozen_string_literal: true

require_relative '../models/connecticut_arrests_additional'
require_relative '../models/connecticut_arrests'
require_relative '../models/connecticut_bonds'
require_relative '../models/connecticut_charges'
require_relative '../models/connecticut_court_hearings'
require_relative '../models/connecticut_court_hearings'
require_relative '../models/connecticut_holding_facilities'
require_relative '../models/connecticut_inmate_additional_info'
require_relative '../models/connecticut_inmate_ids'
require_relative '../models/connecticut_inmate_statuses'
require_relative '../models/connecticut_inmates_runs'
require_relative '../models/connecticut_parole_booking_dates'
require_relative '../models/connecticut_inmates'


class Keeper
  def initialize
    @run_object = RunId.new(ConInmatesRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def get_inmates()
    ConInmates.pluck(:data_source_url)
  end

  def insert_inmate(data_hash)
    old_record = ConInmates.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConInmates.insert(data_hash)
      return ConInmates.last.id
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
      return old_record.first[:id]
    else
      return old_record.first[:id]
    end
  end

  def insert_inmate_ids(data_hash)
    old_record = ConInmateIds.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConInmateIds.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def insert_inmate_additional_info(data_hash)
    old_record = ConInmateAdditionalInfo.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConInmateAdditionalInfo.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def insert_statuses(data_hash)
    old_record = ConInmateStatuses.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConInmateStatuses.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def insert_arrests(data_hash)
    old_record = ConArrests.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConArrests.insert(data_hash)
      return ConArrests.last.id
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
      return old_record.first[:id]
    else
      return old_record.first[:id]
    end
  end

  def insert_arrests_additional(data_hash)
    old_record = ConArrestsAdditional.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConArrestsAdditional.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def insert_charges(data_hash)
    old_record = ConCharges.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConCharges.insert(data_hash)
      return ConCharges.last.id
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
      return old_record.first[:id]
    else
      return old_record.first[:id]
    end
  end

  def insert_bonds(data_hash)
    old_record = ConBonds.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConBonds.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def insert_court_hearings(data_hash)
    old_record = ConCourtHearings.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConCourtHearings.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def insert_holding_facilities(data_hash)
    old_record = ConHoldingFacilities.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConHoldingFacilities.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def insert_parole_booking_dates(data_hash)
    old_record = ConParoleBookingDates.where(data_source_url: data_hash[:data_source_url])
    if old_record.empty?
      ConParoleBookingDates.insert(data_hash)
    elsif old_record.first[:md5_hash] != data_hash[:md5_hash]
      old_record.update(data_hash.except(:created_at))
    end
  end

  def finish
    @run_object.finish
  end
end
