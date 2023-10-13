# frozen_string_literal: true
require_relative '../models/mi_raw_run'
require_relative '../models/mi_raw_expenses'
require_relative '../models/mi_raw_committees'
require_relative '../models/mi_raw_receipts'
require_relative '../models/mi_raw_contributions'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(MIRAWRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(list_of_hashes, model)
    return unless list_of_hashes
    list_of_hashes = list_of_hashes.map {|hash| add_run_id(hash)}
    list_of_hashes.each_slice(5000).to_a.each { |hash| model.insert_all(hash) }
  end

  def update_records_committees(data_array, model)
    data_array.each_slice(5000).to_a.each do |data|
      md5_hash = data.map { |hash| hash.slice(:md5_hash)}.flat_map(&:values)
      model.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)
    end
  end

  def update_records_expenses(data_array, model)
    data_array.each_slice(5000).to_a.each do |data|
      md5_hash = data.map { |hash| hash.slice(:md5_hash)}.flat_map(&:values)
      model.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)
    end
  end

  def update_records_receipts(data_array, model)
    data_array.each_slice(5000).to_a.each do |data|
      md5_hash = data.map { |hash| hash.slice(:md5_hash)}.flat_map(&:values)
      model.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)
    end
  end

  def update_records_contributions(data_array, model)
    data_array.each_slice(5000).to_a.each do |data|
      md5_hash = data.map { |hash| hash.slice(:md5_hash)}.flat_map(&:values)
      model.where(md5_hash:md5_hash).update_all(touched_run_id:run_id)
    end
  end

  def mark_deleted
    db_models = [MIRAWExpenses, MIRAWCommittees, MIRAWReceipts, MIRAWContributions]
    db_models.each do |db_model|
      db_model.where.not(touched_run_id:run_id).update_all(deleted:1)
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

