# frozen_string_literal: true
require_relative '../models/ny_runs'
require_relative '../models/us_districts'
require_relative '../models/us_schools'
require_relative '../models/ny_assess'
require_relative '../models/ny_enroll'
require_relative '../models/ny_grad'
require_relative '../models/ny_salarie'
require_relative '../models/ny_safe'
require_relative '../models/ny_info'
require_relative '../models/ny_absenteeism'
require_relative '../models/ny_assessment_elp'
require_relative '../models/ny_assessment_regents'
require_relative '../models/ny_expenditures'

class Keeper

  DB_MODELS = {'ny_info' => NyInfo, 'us_school' => UsSchools, 'us_district' => UsDistricts, 'ny_enroll' => NyEnroll, 'ny_grad' => NyGrad, 'ny_assess' => NyAssess, 'ny_safe' => NySafe, 'ny_salarie' => NySalarie, 'ny_absen' => NyAbsen, 'ny_exp' => NyExp, 'ny_elp' => NyElp, 'ny_reg' => NyReg}

  attr_reader :run_id

  def initialize
    @run_object = RunId.new(NyRuns)
    @run_id = @run_object.run_id
  end

  def pluck_district_table_data(key)
    DB_MODELS[key].where(:state => 'NY').pluck(:number, :name, :nces_id, :type, :phone, :address, :city, :state, :zip, :zip_4, :data_source_url, :md5_hash)
  end

  def insert_district_data(district_data,run_id)
    district_data.each do |record|
      NyInfo.insert(:is_district => 1, :number => record[0], :name => record[1], :nces_id => record[2], :type => record[3], :phone => record[4], :address => record[5],
      :city => record[6],:state => record[7], :zip => record[8], :zip_4 => record[9], :data_source_url => record[10], :md5_hash => record[11], :run_id => run_id, :touched_run_id => run_id)
    end
  end

  def pluck_school_table_data(key)
    DB_MODELS[key].where(:state => 'NY').pluck(:number, :name, :nces_id, :type, :phone, :address, :city, :state, :zip, :zip_4,
    :district_number, :low_grade, :high_grade, :charter, :magnet, :title_1_school, :title_1_school_wide, :data_source_url, :md5_hash)
  end

  def insert_school_data(school_data,run_id)
    school_data.each do |record|
      district_id = NyInfo.where(:number => record[10]).pluck(:id).first
      NyInfo.insert(:is_district => 0, :district_id => district_id, :number => record[0], :name => record[1], :nces_id => record[2], :type => record[3], :phone => record[4], :address => record[5],
      :city => record[6],:state => record[7], :zip => record[8], :zip_4 => record[9], :low_grade => record[11], :high_grade => record[12], :charter => record[13], :magnet => record[14],
      :title_1_school => record[15], :title_1_school_wide => record[16], :data_source_url => record[17], :md5_hash => record[18], :run_id => run_id, :touched_run_id => run_id)
    end
  end

  def insert_records(data_array, key)
    data_array.each_slice(5000){ |data| DB_MODELS[key].insert_all(data) } unless data_array.empty?
  end

  def pluck_ids_numbers
    NyInfo.pluck(:id, :number)
  end

  def pluck_ids_names
    NyInfo.pluck(:id, :name)
  end

  def get_inserted_md5
    NyInfo.pluck(:md5_hash)
  end

  def finish
    @run_object.finish
  end

end
