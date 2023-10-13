# frozen_string_literal: true
require_relative '../models/la_campaign_runs'
require_relative '../models/la_campaign_candidates'
require_relative '../models/la_campaign_committees'
require_relative '../models/la_campaign_contributions'
require_relative '../models/la_campaign_expenditures'
require_relative '../models/la_campaign_political_action_committees'

class Keeper

  DB_MODELS = { 'la_can' => LaCampaignCand,'la_com' => LaCampaignCom,'la_exp' => LaCampaignExp,'la_cont' => LaCampaignCont,'la_pac' => LaCampaignPac }

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(LaCampaignRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array, key)
    data_array.each_slice(5000){ |data| DB_MODELS[key].insert_all(data) } unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

  def update_touched_run_id(md5_array, key)
    DB_MODELS[key].where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def mark_delete(key)
    DB_MODELS[key].where("touched_run_id is NULL or touched_run_id != #{run_id}").update_all(:deleted => 1)
  end

end
