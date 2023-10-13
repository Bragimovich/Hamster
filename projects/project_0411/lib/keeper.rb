# frozen_string_literal: true
require_relative '../models/sd_sc_case_consolidations'
require_relative '../models/sd_sc_case_info'
require_relative '../models/sd_sc_case_party'
require_relative '../models/sd_sc_case_pdfs_on_aws'
require_relative '../models/sd_sc_case_relations'
require_relative '../models/sd_sc_case_run'

class Keeper

  DB_MODELS = {"info" => TableInfo, "consolidation" => TableConsolidation, "aws" => TableAws, "relations" => TableRelations, "party_0" => TableParty, "party_1" => TableParty}
  UPDATE_DB = {"info" => TableInfo, "consolidation" => TableConsolidation, "aws" => TableAws, "party_0" => TableParty, "party_1" => TableParty}

  def initialize
    @run_object = RunId.new(TableRun)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def finish
    @run_object.finish
  end

  def make_insertions(*params)
    DB_MODELS.keys.each_with_index do |key, index|
      DB_MODELS[key].insert_all(params[index]) unless (params[index].nil?) || (params[index].empty?)
    end
  end

  def update_touched_run_id(*params)
    UPDATE_DB.keys.each_with_index do |key, index|
      UPDATE_DB[key].where(md5_hash: params[index]).update_all(touched_run_id: run_id) unless (params[index].nil?) || (params[index].empty?)
    end
  end

  def mark_deleted
    UPDATE_DB.keys.each_with_index do |key, index|
      UPDATE_DB[key].where.not(touched_run_id: run_id).update_all(deleted: 1)
    end
  end

  def mark_download_status(id)
    TableRun.where(id: run_id).update(download_status: "True")
  end

  def download_status(id)
    TableRun.where(id: run_id).pluck(:download_status)
  end
end
