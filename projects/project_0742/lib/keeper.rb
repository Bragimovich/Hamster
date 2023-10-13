# frozen_string_literal: true
require_relative '../models/va_raw_runs'
require_relative '../models/va_schduleA'
require_relative '../models/va_schduleB'
require_relative '../models/va_schduleC'
require_relative '../models/va_schduleD'
require_relative '../models/va_schduleE'
require_relative '../models/va_schduleF'
require_relative '../models/va_schduleG'
require_relative '../models/va_schduleH'
require_relative '../models/va_schduleI'
require_relative '../models/va_candidate_committee'
require_relative '../models/va_fedral_committee'
require_relative '../models/va_inaugural_committee'
require_relative '../models/va_out_state_political_committee'
require_relative '../models/va_party_committee'
require_relative '../models/va_raw_political_action_committee'
require_relative '../models/va_referendum_committee'
require_relative '../models/va_raw_report'


class Keeper

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(VaRuns)
    @run_id = @run_object.run_id
  end

  def finish
    @run_object.finish
  end

  def insert_records(data_array,model)
    data_array.each_slice(8000){|data| model.insert_all(data)} unless data_array.empty?
  end

  def update_touch_run_id(md5_array,model)
    md5_array.each_slice(8000){|data| model.where(md5_hash: data).update_all(touched_run_id: run_id)} unless md5_array.empty?
  end

  def mark_delete(model)
    model.where.not(touched_run_id: run_id).update_all(deleted: 1)
  end

end
