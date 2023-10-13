# frozen_string_literal: true
require_relative '../models/bill_gates_foundation_grants.rb'
require_relative '../models/bill_gates_foundation_grants_runs.rb'

class Keeper
  attr_reader :run_id

  def initialize
    @run_object = RunId.new(BillGatesFoundationGrantsRuns)
    @run_id = @run_object.run_id
  end

  def insert_data(list_of_hashes)
    return if list_of_hashes.empty?
    lish_of_hashes = list_of_hashes.map { |hash| add_run_id(hash) }
    list_of_hashes.each_slice(500).to_a.each do |hash|
      BillGatesFoundationGrants.insert_all(hash)
    end
  end

  def update_data(list_of_hashes)
    lish_of_hashes = list_of_hashes.map { |hash| add_run_id(hash) }
    list_of_hashes.each_slice(500).to_a.each do |array_hash|
      grant_id = array_hash.pluck(:grant_id)
      md5_hash = array_hash.pluck(:md5_hash)
      BillGatesFoundationGrants.where(grant_id:grant_id).where(md5_hash:md5_hash).where.not(run_id:@run_id).update_all("deleted = 0, touched_run_id = #{@run_id}")
      BillGatesFoundationGrants.where(grant_id:grant_id).where.not(md5_hash:md5_hash).update_all(deleted:1)
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
