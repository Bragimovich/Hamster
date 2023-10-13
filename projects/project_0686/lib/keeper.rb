require_relative '../models/nv_runs'
require_relative '../models/nv_assessment'
require_relative '../models/nv_dropout_rate'
require_relative '../models/nv_enrollment'
require_relative '../models/nv_financial_spending'
require_relative '../models/nv_graduation_rates'
require_relative '../models/nv_safety_incidents'
require_relative '../models/nv_general_info'

class Keeper
  DB_MODELS = {"assessment" => NvAssessment, "dropout" => NvDropOutRate, "enrollment" => NvEnrollment, "financial" => NvFinancialSpending, "graduation_rates" => NvGraduationRates, "safety" => NvSafetyIncidents}

  def initialize
    @run_object = RunId.new(NvRuns)
    @run_id = @run_object.run_id
  end

  attr_reader :run_id

  def insert_records(key, hash_array)
    hash_array.each_slice(5000) do |data|
      DB_MODELS[key].insert_all(data)
    end
  end

  def update_touch_run_id(key, md5_array)
    DB_MODELS[key].where(:md5_hash => md5_array).update_all(:touched_run_id => run_id) unless md5_array.empty?
  end

  def delete_using_touch_id(key)
    DB_MODELS[key].where.not(:touched_run_id => run_id).update_all(:deleted => 1)
  end

  def finish
    @run_object.finish
  end

  def fetch_general_number_id
    NvGeneralInfo.pluck("number", "id")
  end
end
