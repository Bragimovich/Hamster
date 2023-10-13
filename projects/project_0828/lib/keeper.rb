# frozen_string_literal: true
require_relative '../models/ny_runs'
require_relative '../models/ny_erie_arrests'
require_relative '../models/ny_erie_inmates'
require_relative '../models/ny_erie_holding_facilities'
require_relative '../models/ny_erie_inmate_ids'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NyRuns)
    @run_id = @run_object.run_id
  end

  def insert_arrest(list_of_hash)
    return if list_of_hash.empty?
    list_of_hash = list_of_hash.map {|hash| add_run_id(hash)}
    list_of_hash = list_of_hash.select {|hash| hash[:full_name] != nil}

    ny_erie_inmates = list_of_hash.map {|hash| hash.slice(:full_name, :birthdate, :data_source_url, :md5_hash, :run_id, :touched_run_id)}
    md5_hash = list_of_hash.map {|hash| hash.slice(:md5_hash)}.map(&:values).flatten
    NyErieInmates.insert_all(ny_erie_inmates)
    NyErieInmates.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)

    ny_erie_arrests = list_of_hash.each do |hash|
      hash[:inmate_id] = NyErieInmates.where(md5_hash:hash[:md5_hash]).first.id
    end

    ny_erie_arrests_map = ny_erie_arrests.map {|hash| hash.slice(:inmate_id, :booking_date, :data_source_url, :md5_hash, :run_id, :touched_run_id)}
    NyErieArrests.insert_all(ny_erie_arrests_map)
    NyErieArrests.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)

    ny_erie_inmates_ids = list_of_hash.each do |hash|
      hash[:inmate_id] = NyErieInmates.where(md5_hash:hash[:md5_hash]).first.id
    end

    ny_erie_inmates_ids_map = ny_erie_inmates_ids.map {|hash| hash.slice(:inmate_id, :number, :type, :data_source_url, :md5_hash, :run_id, :touched_run_id)}
    NyErieInmatesIds.insert_all(ny_erie_inmates_ids_map)
    NyErieInmatesIds.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)

    ny_erie_holding_facilities = list_of_hash.each do |hash|
      hash[:arrest_id] = NyErieArrests.where(md5_hash:hash[:md5_hash]).first.id
    end

    ny_erie_holding_facilities_map = ny_erie_holding_facilities.map {|hash| hash.slice(:arrest_id, :facility, :data_source_url, :md5_hash, :run_id, :touched_run_id)}
    NyErieHoldingFacilities.insert_all(ny_erie_holding_facilities_map)
    NyErieHoldingFacilities.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)
  end

  def mark_deleted
    db_models = [NyErieInmates, NyErieArrests, NyErieInmatesIds, NyErieHoldingFacilities]
    db_models.each do |db|
      db.where.not(touched_run_id:run_id).update_all(deleted:1)
    end
  end

  def add_run_id(hash)
    hash[:run_id] = @run_id
    hash[:touched_run_id] = @run_id
    hash
  end

  def finish
    @run_object.finish
  end
end
