# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/all_urls'
require_relative '../lib/manager_helper'

class Manager < Hamster::Harvester
  include AllUrls
  include ManagerHelper

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @scraper  = Scraper.new
    @parser    = Parser.new
    @subfolder_path = "#{@keeper.run_id}"
  end

  def download
    names = ['demographic', 'assessment' , 'dicipline', 'financial', 'graduation_5_year_rate', 'graduation_4_year_rate', 'drop_out_rate', 'crt_five_to_eight_district', 'crt_nine_to_ten_district', 'ccr_elven_district', 'naa_district', 'elpa_district', 'crt_prior_district', 'grade_prior_district', 'writing_prior_district', 'naa_prior_district', 'hspe_prior_district', 'crt_three_to_eight_school', 'crt_five_to_eight_school', 'crt_nine_to_ten_school', 'ccr_elven_school', 'naa_school', 'elpa_school', 'crt_prior_school', 'grade_prior_school', 'writing_prior_school', 'naa_prior_school', 'hspe_prior_school']
    url_params           = urls
    url_params.each_with_index do |url, index|
      connect_and_save(names[index], url)
    end
  end

  def store
    all_assessment_data = []
    run_id = keeper.run_id
    general_id_info   = keeper.fetch_general_number_id
    demographic_array, demograph_md5 = fetch_demographic_data(run_id, general_id_info)
    dicipline_array, dicipline_md5   = fetch_dicipline_data(run_id, general_id_info)
    financial_array, financial_md5   = fetch_financial_data(run_id, general_id_info)
    graduation_rate_array, graduation_rate_md5 = fetch_graduation_rate_data(run_id, general_id_info)
    drop_out_rate_array, drop_out_rate_md5     = fetch_drop_out_rate_data(run_id, general_id_info)
    all_assessment_data, all_assessment_md5    = get_all_assessment_data(run_id, general_id_info)
    types = ['assessment', 'dropout', 'enrollment', 'financial', 'graduation_rates', 'safety']
    all_data_array = [all_assessment_data, drop_out_rate_array, demographic_array, financial_array, graduation_rate_array, dicipline_array]
    types.each_with_index do |type, index| 
      keeper.insert_records(type, all_data_array[index])
    end
    all_md5_hashes = [all_assessment_md5, drop_out_rate_md5, demograph_md5, financial_md5, graduation_rate_md5, dicipline_md5]
    types.each_with_index do |type, index|
      keeper.update_touch_run_id(type, all_md5_hashes[index])
      keeper.delete_using_touch_id(type)
    end
    keeper.finish
  end

  private
  attr_accessor :keeper, :parser, :scraper, :subfolder_path
  
  def file_name(name)
    "#{storehouse}store/#{subfolder_path}/#{name}.csv"
  end

  def connect_and_save(file_name, url)
    response = scraper.fetch_csv(url)
    save_csv(response.body, file_name)
  end

  def save_csv(content, name)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/#{name}.csv"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

end
