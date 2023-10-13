require_relative '../models/la_campaign_runs'
require_relative '../models/la_campaign_contributions'
require_relative '../models/la_campaign_expenditures'

class Keeper

  DB_MODELS = {"expenditure" => LaCampaignExpenditures, "contribution" => LaCampaignContributions}

  def initialize
    @run_object = RunId.new(LaCampaignRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def fetch_contribution_db_md5(key, column, start_date, end_date)
    DB_MODELS[key].where("#{column} >= '#{start_date}' and #{column} <= '#{end_date}'").group(:md5_hash).count
  end

  def mark_ids_delete(key, del_records)
    ids_extract = DB_MODELS[key].where(:deleted => 0, :md5_hash => del_records.keys).group(:md5_hash).pluck("md5_hash, GROUP_CONCAT(id)")
    all_old_ids = []
    ids_extract.each do |value|
      ids = value[-1].split(",").map(&:to_i).sort
      del_count = del_records[value[0]]
      ids = ids[0..del_count]
      all_old_ids << ids
    end
    all_old_ids = all_old_ids.flatten
    DB_MODELS[key].where(:id => all_old_ids).update_all(:deleted => 1) unless all_old_ids.empty?
  end

  def insert_records(key, hash_array)
    hash_array.each_slice(5000) do |data|
      DB_MODELS[key].insert_all(data)
    end
  end

  def finish
    @run_object.finish
  end
end
