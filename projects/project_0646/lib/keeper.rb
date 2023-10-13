# frozen_string_literal: true
require_relative '../models/mo_cc_runs'
require_relative '../models/mo_info'
require_relative '../models/mo_judge'
require_relative '../models/mo_party'
require_relative '../models/mo_activity'

class Keeper

  MODELS = {'info' => MoInfo,'activity' => MoActivity,'party' => MoParty,'judge' => MoJudge}

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(MoRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array,key)
    MODELS[key].insert_all(data_array) unless data_array.empty?
  end

  def finish
    @run_object.finish
  end

  def mark_delete(key)
    ids_extract = MODELS[key].where(:deleted => 0).group(:case_id).having("count(*) > 1").pluck("case_id, GROUP_CONCAT(id)")
    all_old_ids = ids_extract.map{|e| e.last.split(',').map(&:to_i)}.each{|e| e.delete(e.max)}.flatten
    MODELS[key].where(:id => all_old_ids).update_all(:deleted => 1)
  end

  def get_case_numbers
    ids = MoInfo.where("EXTRACT(year FROM case_filed_date) BETWEEN 2020 AND 2023").where("status_as_of_date = 'Not Disposed' OR status_as_of_date = 'Uncontested'").pluck(:case_id)
  end

end
