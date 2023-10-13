# frozen_string_literal: true
require_relative '../models/ak_runs'
require_relative '../models/ak_assessment'
require_relative '../models/ak_enrollment'
require_relative '../models/ak_general_info'
require_relative '../models/ak_graduation'
require_relative '../models/ak_revenue'
require_relative '../models/ak_teacher_count'

class Keeper

  MODELS = {'info' => AkInfo,'enrollment' => AkEnrollment,'graduation' => AkGraduation,'assessment' => AkAssessment,'revenue' => AkRevenue,'teacher_count' => AkTeacherCount}

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(AkRuns)
    @run_id = @run_object.run_id
  end

  def insert_records(data_array, key)
    data_array.each_slice(10000){ |data| MODELS[key].insert_all(data) } unless data_array.empty?
  end

  def get_ids_and_names
    AkInfo.pluck(:id, :name)
  end

  def finish
    @run_object.finish
  end

end
