# frozen_string_literal: true

require_relative '../models/new_york_inmates'
require_relative '../models/new_york_inmate_additional_info'
require_relative '../models/new_york_inmate_ids'
require_relative '../models/new_york_arrests'
require_relative '../models/new_york_arrests_additional'
require_relative '../models/new_york_charges'
require_relative '../models/new_york_charges_additional'
require_relative '../models/new_york_bonds'
require_relative '../models/new_york_court_hearings'
require_relative '../models/new_york_holding_facilities'
require_relative '../models/new_york_holding_facilities_additional'
require_relative '../models/runs'

class Keeper < Hamster::Harvester
  attr_writer :data_hash

  def initialize
    super
    @run_object = RunId.new(Runs)
    @run_id = @run_object.run_id
  end

  def store_inmate
    inmate = digest_update(NewYorkInmates, @data_hash[:inmate])
    @data_hash.merge!({ inmate_id: inmate.id })
  end

  def store_additional_info
    additional_info_arr = []
    @data_hash[:info].each do |row, value|
      if row == ("height") || row == ("weight") || row == ("hair_color") || row == ("eye_color") || row == ("nativity")
        unless value.nil? || value.empty?
          hash = {
              key: row,
              value: value,
              inmate_id: @data_hash[:inmate_id],
              run_id: @run_id,
              touched_run_id: @run_id
          }
          hash.merge!({md5_hash: create_md5_hash(hash), data_source_url: "https://a073-ils-web.nyc.gov/inmatelookup/pages/home/home.jsf"})
          additional_info_arr << hash
        end
      end
    end
    NewYorkInmateAdditionalInfo.insert_all(additional_info_arr)
    Hamster.close_connection(NewYorkInmateAdditionalInfo)
  end

  def store_inmate_ids
    @data_hash[:inmate_ids].merge!({inmate_id: @data_hash[:inmate_id] })
    digest_update(NewYorkInmateIds, @data_hash[:inmate_ids])
  end

  def store_arrests
    @data_hash[:arrests].merge!({inmate_id: @data_hash[:inmate_id] })
    arrest = digest_update(NewYorkArrests, @data_hash[:arrests])
    @data_hash.merge!({arrest_id: arrest.id })
  end

  def store_arrests_additional  
    additional_arr = []
    @data_hash[:arrests_additional].each do |row, value|
      if row == ("current_housing_facility") || row == ("arrest_number") || row == ("bail_status") || row == ("actual_release_date") || row == ("discharge_reason") || row == ("disposition")
        unless value.nil? || value.empty?
          hash = {
              key: row,
              value: value,
              arrest_id: @data_hash[:arrest_id],
              run_id: @run_id,
              touched_run_id: @run_id
          }
          hash.merge!({md5_hash: create_md5_hash(hash), data_source_url: "https://a073-ils-web.nyc.gov/inmatelookup/pages/home/home.jsf"})
          additional_arr << hash
        end
      end
    end
    NewYorkArrestsAdditional.insert_all(additional_arr)
    Hamster.close_connection(NewYorkArrestsAdditional)
  end

  def store_charge
    unless @data_hash[:charge].nil?
      @data_hash[:charge].each do |row|
        row.merge!({arrest_id: @data_hash[:arrest_id] })
        charge = digest_update(NewYorkCharge, row)
        row.merge!({ charge_id: charge.id })
      end
    end

    unless @data_hash[:warrants].nil?
      @data_hash[:warrants].each do |row|
        row.merge!({arrest_id: @data_hash[:arrest_id] })
        charge = digest_update(NewYorkCharge, row)
        row.merge!({ charge_id: charge.id })
      end
    end
  end

  def store_charge_additional
    additional_arr = []
    unless @data_hash[:charge_additional].empty?
      @data_hash[:charge_additional].each_with_index do |hash, index|
        hash.each do |row, value|
          if row == ("indictment") || row == ("credit_card_amount") || row == ("conviction_date") || row == ("sentence_date") 
            unless value.nil? || value.empty?
              hash = {
                key: row,
                value: value,
                charge_id: @data_hash[:charge][index][:charge_id],
                run_id: @run_id,
                touched_run_id: @run_id
              }
              hash.merge!({md5_hash: create_md5_hash(hash), data_source_url: "https://a073-ils-web.nyc.gov/inmatelookup/pages/home/home.jsf"})
              additional_arr << hash
            end
          end
        end
      end
    end
    unless @data_hash[:warrants].empty?
      @data_hash[:warrants].each_with_index do |hash, index|
        hash.each do |row, value|
          if row == (:warrant_id) || row == (:warrant_type)
            unless value.nil? || value.empty?
              hash = {
                key: row,
                value: value,
                charge_id: @data_hash[:warrants][index][:charge_id],
                run_id: @run_id,
                touched_run_id: @run_id
              }
              hash.merge!({md5_hash: create_md5_hash(hash), data_source_url: "https://a073-ils-web.nyc.gov/inmatelookup/pages/home/home.jsf"})
              additional_arr << hash
            end
          end
        end
      end
    end
    unless additional_arr.empty?
      NewYorkChargeAdditional.insert_all(additional_arr)
      Hamster.close_connection(NewYorkChargeAdditional)
    end
  end

  def store_bonds
    unless @data_hash[:bonds].nil?
      @data_hash[:bonds].merge!({arrest_id: @data_hash[:arrest_id] })
      digest_update(NewYorkBonds, @data_hash[:bonds])
    end
  end

  def store_court_hearings
    unless @data_hash[:court_hearings].nil?
      @data_hash[:court_hearings].each_with_index do |row, index|
        row.merge!({charge_id: @data_hash[:charge][index][:charge_id] })
        digest_update(NewYorkCourtHearings, row)
      end
    end
  end

  def store_holding_facilities
    unless @data_hash[:holding_facilities].nil?
      @data_hash[:holding_facilities].merge!({ arrest_id: @data_hash[:arrest_id] })
      holding_facilities = digest_update(NewYorkHoldingFacilities, @data_hash[:holding_facilities])
      @data_hash[:facilities_additional].merge!({ holding_facility_id: holding_facilities.id }) unless @data_hash[:facilities_additional].nil?
    end
  end

  def store_facilities_additional
    unless @data_hash[:facilities_additional].nil?
      digest_update(NewYorkHoldingFacilitiesAdditional, @data_hash[:facilities_additional])
    end
  end

  def digest_update(object, h)
    hash = object.flail { |key| [key, h[key]] }
    digest = object.find_by(md5_hash: create_md5_hash(hash))
    if digest.nil?
      hash.merge!({run_id: @run_id, touched_run_id: @run_id, data_source_url: "https://a073-ils-web.nyc.gov/inmatelookup/pages/home/home.jsf", md5_hash: create_md5_hash(hash)})
      object.store(hash)
    else
      digest.update(touched_run_id: @run_id, deleted: false) 
      digest
    end
  end

  def finish
    @run_object.finish
  end

  def create_md5_hash(hash)
    str = ""
    hash.each do |field|
      unless field.include?(:data_source_url) || field.include?(:run_id) || field.include?(:touched_run_id) || field.include?(:md5_hash) || field.include?(:age)
        str += field.to_s
      end
    end
    digest = Digest::MD5.new.hexdigest(str)
  end

  def update_delete_status
    models = [
      NewYorkInmates, NewYorkInmateAdditionalInfo, NewYorkInmateIds, NewYorkArrests, NewYorkArrestsAdditional, NewYorkCharge, 
      NewYorkChargeAdditional, NewYorkBonds, NewYorkCourtHearings, NewYorkHoldingFacilities, NewYorkHoldingFacilitiesAdditional
    ]
    models.each do |model|
      model.where(deleted: 0).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    end
  end
  
  def finish
    @run_object.finish
  end
end
