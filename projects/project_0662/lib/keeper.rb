require_relative '../models/co_runs'
require_relative '../models/co_assessment_sat_psat'
require_relative '../models/co_assessment_cmas'
require_relative '../models/co_dropout_by_race'
require_relative '../models/co_dropout_social'
require_relative '../models/co_graduation_race'
require_relative '../models/co_graduation_social'
require_relative '../models/co_attendance'
require_relative '../models/co_safety'
require_relative '../models/co_salary_avg'
require_relative '../models/co_teachers_student_ratio'
require_relative '../models/co_general_info'
require_relative '../lib/headers'

class Keeper
  include Headers
  def initialize
    @run_object = RunId.new(CoRuns)
    @run_id = @run_object.run_id
  end

  def store_data(data, db_name, key)
    models_hash = make_model
    db_name = models_hash[:"#{key}"][:"#{db_name}"]
    insert_all(db_name, data)
  end

  def insert_all(name, data)
    model = name.constantize
    data.count < 5000 ? model.insert_all(data) : data.each_slice(5000){|data| model.insert_all(data)} unless data.empty?
  end

  def get_ids
    ids_extract = CoGeneral.pluck("number, id", "is_district")
  end

  def get_urls
    array = []
    name_array = ["CoCmas", "CoSat", "CoDropout", "CoSocial", "CoGraduation", "CoGradSocial", "CoAttendance", "CoSalary", "CoRatio", "CoSafety"]
    name_array.each do |name|
      model = name.constantize
      array << model.pluck("data_source_url").uniq
    end
    array.flatten
  end

  attr_reader :run_id

  def finish
    @run_object.finish
  end
end
