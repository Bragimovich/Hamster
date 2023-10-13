# frozen_string_literal: true
require_relative '../models/la_runs'
require_relative '../models/la_info'
require_relative '../models/la_add_info'
require_relative '../models/la_activity'
require_relative '../models/la_aws'
require_relative '../models/la_party'
require_relative '../models/la_relation'

class Keeper

  DB_MODELS = {'info' => LaInfo,'activity' => LaActivity,'party' => LaParty,'aws' => LaAws,'relation' => LaRelation,'add_info' => LaAddInfo}

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(LaRuns)
    @run_id = @run_object.run_id
  end

  def finish_download
    current_run = LaRuns.find_by(id: run_id)
    current_run.update download_status: 'finish'
  end

  def download_status
    LaRuns.pluck(:download_status).last
  end

  def update_touch_run_id(md5_array, key)
    DB_MODELS[key].where(md5_hash: md5_array).update_all(touched_run_id: run_id) unless md5_array.empty?
  end

  def insert_records(data_array,key)
    DB_MODELS[key].insert_all(data_array) unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

  def mark_delete(key)
    DB_MODELS[key].where.not(touched_run_id: run_id).update_all(deleted: 1)
  end
end
