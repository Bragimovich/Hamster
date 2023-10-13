# frozen_string_literal: true
require_relative '../models/ny_nysboe_runs'
require_relative '../models/ny_nyccfb_contributions'
require_relative '../models/ny_nyccfb_expenditures'
require_relative '../models/ny_nyccfb_intermediaries'
require_relative '../models/ny_nysboe_filers'
require_relative '../models/ny_nysboe_reports'
require_relative '../models/ny_nysboe_filers_candidates'

class Keeper

  DB_MODELS = {'cont' => NyCont, 'expend' => NyExp, 'inter' => NyInt, 'filer' => NyFil, 'repo' => NyRep, 'can' => NyCandidate}

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NyNysRuns)
    @run_id = @run_object.run_id
  end

  def finish
    @run_object.finish
  end

  def insert_records(data_array, key)
    DB_MODELS[key].insert_all(data_array) unless data_array.empty?
  end

  def update_touched_run_id(md5_array, key)
    DB_MODELS[key].where(md5_hash: md5_array).update_all(touched_run_id: run_id) unless md5_array.empty?
  end

  def mark_delete(key)
    DB_MODELS[key].where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

end
