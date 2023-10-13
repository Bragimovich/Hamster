require_relative '../models/la_assessment_kg_entry'
require_relative '../models/la_assessment_leap_subgroup'
require_relative '../models/la_assessment_leap'
require_relative '../models/la_discipline_ethnicity_grade'
require_relative '../models/la_discipline_rate'
require_relative '../models/la_discipline_reason'
require_relative '../models/la_enrollment'
require_relative '../models/la_general_info'
require_relative '../models/la_schools_runs'

class Keeper < Hamster::Scraper

  def initialize
    @run_object = RunId.new(LaRunId)
    @run_id = @run_object.run_id
  end

  DB_MODELS = { 'kg_entry' => KgEntry, 'assessment_leap_subgroup' => LeapSubgroup, 'assessment_leap' => AssessmentLeap, 'discipline_ethnicity_grade' => EthnicityGrade, 'discipline_rate' => DisciplineRate, 'discipline_reason' => DisciplineReason, 'enrollment' => Enrollment }

  attr_reader :run_id

  def get_data
    LaGeneralInfo.all
  end

  def insert_data(data_array, key)
    md5_hash_array = data_array.map { |e| e[:md5_hash] }
    data_array.each_slice(5000) { |data|  DB_MODELS[key].insert_all(data) }
    md5_hash_array.each_slice(5000) { |data|  DB_MODELS[key].where(:md5_hash => data).update_all(:touched_run_id => run_id) }
  end

  def add_district(hash)
    LaGeneralInfo.insert(hash)
    [LaGeneralInfo.last[:id],  LaGeneralInfo.all]
  end

  def get_district_id(number)
    LaGeneralInfo.where(number: number)[0][:id] rescue nil
  end

  def mark_delete
    DB_MODELS.keys.each do |model|
      DB_MODELS[model].where.not(:touched_run_id => run_id).update_all(:deleted => 1)
    end
  end

  def finish
    @run_object.finish
  end
end
