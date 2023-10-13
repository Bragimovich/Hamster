# frozen_string_literal: true
require_relative '../models/me_runs'
require_relative '../models/us_districts'
require_relative '../models/us_schools'
require_relative '../models/me_enrollment'
require_relative '../models/me_graduation'
require_relative '../models/me_performance_indicator'
require_relative '../models/me_finance'
require_relative '../models/me_general_info'
require_relative '../models/me_assessment'

class Keeper

  DB_MODELS = {'me_general_info' => MeGeneralInfo, 'us_school' => UsSchools, 'us_district' => UsDistricts, 'me_graduation' => MeGraduation, 'me_performance_indicator' => MePerformanceIndicator, 'me_enrollment' => MeEnrollment, 'me_assessment' => MeAssessment, 'me_finance'=> MeFinance}

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(MeRuns)
    @run_id = @run_object.run_id
  end

  def pluck_district_table_data
    UsDistricts.where(:state => 'ME').pluck(:number, :name, :nces_id, :type, :phone, :address, :city, :state, :zip, :zip_4, :data_source_url, :md5_hash)
  end

  def pluck_school_table_data
    UsSchools.where(:state => 'ME').pluck(:number, :name, :nces_id, :type, :phone, :address, :city, :state, :zip, :zip_4,
    :district_number, :low_grade, :high_grade, :charter, :magnet, :title_1_school, :title_1_school_wide, :data_source_url, :md5_hash)
  end

  def pluck_ids_numbers_without_district
    MeGeneralInfo.where(is_district:0).pluck(:id, :number)
  end

  def pluck_ids_numbers_with_district
    MeGeneralInfo.where(is_district:1).pluck(:id, :number)
  end

  def insert_general_info_data(district_data, run_id)
    district_data.each do |record|
    MeGeneralInfo.insert(:is_district => 1, :number => record[0], :name => record[1], :nces_id => record[2], :type => record[3], :phone => record[4], :address => record[5],
    :city => record[6],:state => record[7], :zip => record[8], :zip_4 => record[9], :data_source_url => record[10], :md5_hash => record[11], :run_id => run_id, :touched_run_id => run_id)
    end
  end

  def insert_records(data_array, key)
    data_array.each_slice(10000){ |data| DB_MODELS[key].insert_all(data) } unless data_array.empty?
  end

  def insert_school_data(school_data, run_id)
    school_data.each do |record|
    district_id = MeGeneralInfo.where(:number => record[10]).pluck(:id).first
    MeGeneralInfo.insert(:is_district => 0, :district_id => district_id, :number => record[0], :name => record[1], :nces_id => record[2], :type => record[3], :phone => record[4], :address => record[5],:city => record[6],:state => record[7], :zip => record[8], :zip_4 => record[9], :low_grade => record[11], :high_grade => record[12], :charter => record[13], :magnet => record[14],
        :title_1_school => record[15], :title_1_school_wide => record[16], :data_source_url => record[17], :md5_hash => record[18], :run_id => run_id, :touched_run_id => run_id)
    end
  end

  def finish
    @run_object.finish
  end

end
