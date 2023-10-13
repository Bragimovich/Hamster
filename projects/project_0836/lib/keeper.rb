# frozen_string_literal: true
require_relative '../models/fl_palmbeach_runs'
require_relative '../models/fl_palmbeach_arrests'
require_relative '../models/fl_palmbeach_bonds'
require_relative '../models/fl_palmbeach_charges'
require_relative '../models/fl_palmbeach_holding_facilities'
require_relative '../models/fl_palmbeach_inmate_additional_info'
require_relative '../models/fl_palmbeach_inmate_addresses'
require_relative '../models/fl_palmbeach_inmate_ids'
require_relative '../models/fl_palmbeach_inmates'
require_relative '../models/fl_palmbeach_mugshots'

class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(PalmBeachRuns)
    @run_id = @run_object.run_id
  end

  def finish
    @run_object.finish
  end

  def insert_records(data_array, model)
    model.insert_all(data_array) unless data_array.empty?
  end

  def update_touched_run_id(md5_array, model)
    model.where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def pluck_inmates_ids(data_array, model)
    db_ids = []
    insert_records(data_array, model)
    data_array.each do |data_hash|
      db_ids << model.where(:md5_hash => data_hash[:md5_hash]).pluck(:id).first
    end
    db_ids
  end

  def pluck_arrest_ids(data_array, model)
    db_ids = []
    insert_records(data_array, model)
    data_array.each do |data_hash|
      db_ids << model.where(:md5_hash => data_hash[:md5_hash]).pluck(:inmate_id,:id).first
    end
    db_ids
  end

  def pluck_charge_and_arrest_ids(data_array, model)
    db_ids = []
    insert_records(data_array, model)
    data_array.each do |data_hash|
      db_ids << model.where(:md5_hash => data_hash[:md5_hash]).pluck(:arrest_id,:id).first
    end
    db_ids
  end

  def mark_delete(model)
    model.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

end
