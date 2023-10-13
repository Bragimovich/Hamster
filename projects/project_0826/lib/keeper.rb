# frozen_string_literal: true

require_relative '../models/fl_polk_runs'
require_relative '../models/fl_polk_charges'
require_relative '../models/fl_polk_inmates'
require_relative '../models/fl_polk_mugshots'
require_relative '../models/fl_polk_arrests'
require_relative '../models/fl_polk_inmate_ids'
require_relative '../models/fl_polk_holding_facilities'
require_relative '../models/fl_polk_inmate_additional_info'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(FlPolkRuns)
    @run_id = @run_object.run_id
  end

  def insert_record(data_inmate)
    return if data_inmate.empty?
    data_inmates = data_inmate.map { |hash| add_run_id(hash) }
    inmates = data_inmates.map {|hash| hash.slice(:full_name, :age, :sex, :race, :data_source_url, :run_id, :touched_run_id, :md5_hash)}
    md5_hash = inmates.map {|hash| hash.slice(:md5_hash)}.map(&:values).flatten
    FlPolkInmates.insert_all(inmates)
    FlPolkInmates.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)

    holding_facilities = data_inmate.each { |hash| hash[:inmate_id] = FlPolkInmates.where(md5_hash:hash[:md5_hash]).first.id }
    holding_facilities = data_inmates.map {|hash| hash.slice(:inmate_id, :city, :facility, :data_source_url, :run_id, :touched_run_id, :md5_hash)}
    md5_hash = holding_facilities.map {|hash| hash.slice(:md5_hash)}.map(&:values).flatten
    FlPolkHoldingFacilities.insert_all(holding_facilities)
    FlPolkHoldingFacilities.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)

    additional_info = data_inmate.each { |hash| hash[:inmate_id] = FlPolkInmates.where(md5_hash:hash[:md5_hash]).first.id }
    additional_info = data_inmates.map {|hash| hash.slice(:inmate_id, :height, :weight, :hair_color, :eye_color, :age, :run_id, :touched_run_id, :md5_hash)}
    md5_hash = additional_info.map {|hash| hash.slice(:md5_hash)}.map(&:values).flatten
    FlPolkInmateAdditionalInfo.insert_all(additional_info)
    FlPolkInmateAdditionalInfo.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)

    inmate_ids = data_inmate.each { |hash| hash[:inmate_id] = FlPolkInmates.where(md5_hash:hash[:md5_hash]).first.id }
    inmate_ids = data_inmates.map {|hash| hash.slice(:inmate_id, :number, :data_source_url, :run_id, :touched_run_id, :md5_hash)}
    md5_hash = inmate_ids.map {|hash| hash.slice(:md5_hash)}.map(&:values).flatten
    FlPolkInmateIds.insert_all(inmate_ids)
    FlPolkInmateIds.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)

    inmate_mugshot = data_inmate.each { |hash| hash[:inmate_id] = FlPolkInmates.where(md5_hash:hash[:md5_hash]).first.id }
    inmate_mugshot = data_inmates.map {|hash| hash.slice(:inmate_id, :original_link, :aws_link, :data_source_url, :run_id, :touched_run_id, :md5_hash)}
    md5_hash = inmate_mugshot.map {|hash| hash.slice(:md5_hash)}.map(&:values).flatten
    inmate_mugshot = inmate_mugshot.reject {|hash| hash[:aws_link] == nil }
    FlPolkMugshots.insert_all(inmate_mugshot)
    FlPolkMugshots.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)

    arrests = data_inmate.pluck(:arrest_data)
    arrests = arrests.flat_map(&:itself)
    arrests = arrests.each { |hash| hash[:inmate_id] = FlPolkInmates.where(md5_hash:hash[:md5_hash]).first.id }
    arrests = arrests.each do |hash| 
      add_run_id(hash)
      generate_md5_hash(%i[inmate_id number booking_date booking_number booking_agency description], hash)
    end
    charges = arrests.map {|hash| hash.slice(:number, :description, :counts, :data_source_url, :run_id, :touched_run_id, :md5_hash)}
    arrests = arrests.map {|hash| hash.slice(:inmate_id, :booking_date, :booking_number, :booking_agency, :data_source_url, :run_id, :touched_run_id,:md5_hash)}
    md5_hash = arrests.map {|hash| hash.slice(:md5_hash)}.map(&:values).flatten
    FlPolkArrests.insert_all(arrests)
    FlPolkArrests.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)

    charges = charges.each {|hash| hash[:arrest_id] = FlPolkArrests.where(md5_hash:hash[:md5_hash]).first.id }
    md5_hash = charges.map {|hash| hash.slice(:md5_hash)}.map(&:values).flatten
    FlPolkCharges.insert_all(charges)
    FlPolkCharges.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)
  end

  def add_run_id(hash)
    hash[:run_id] = @run_id
    hash[:touched_run_id] = @run_id
    hash
  end

  def mark_deleted
    db_models = [FlPolkInmates, FlPolkInmateAdditionalInfo, FlPolkInmateIds, FlPolkMugshots, FlPolkArrests, FlPolkCharges, FlPolkHoldingFacilities]
    db_models.each do |db_model|
      db_model.where.not(touched_run_id:run_id).update_all(deleted:1)
    end
  end

  def generate_md5_hash(column, hash)
    md5 = MD5Hash.new(columns: column)
    md5.generate(hash)
    hash[:md5_hash] = md5.hash
  end

  def finish
    @run_object.finish
  end
end
