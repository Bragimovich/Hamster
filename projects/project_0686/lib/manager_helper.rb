require_relative '../lib/parser'

module ManagerHelper

  def initialize(**params)
    super
    @parser   = Parser.new
  end

  def get_all_assessment_data(run_id, general_id_info)
    all_assessment_data = []
    all_assessment_data << parser.fetch_assessment_data(file_name("assessment"), run_id, general_id_info)
    all_assessment_data << parser.fetch_crt_five_to_eight_dist_data(file_name("crt_five_to_eight_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_crt_nine_to_ten_district_data(file_name("crt_nine_to_ten_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_ccr_elven_district_data(file_name("ccr_elven_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_naa_district_data(file_name("naa_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_elpa_district_data(file_name("elpa_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_crt_prior_district_data(file_name("crt_prior_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_grade_prior_district_data(file_name("grade_prior_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_writing_prior_district_data(file_name("writing_prior_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_naa_prior_district_data(file_name("naa_prior_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_hspe_prior_district_data(file_name("hspe_prior_district"), run_id, general_id_info)
    all_assessment_data << parser.fetch_assessment_data(file_name("crt_three_to_eight_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_crt_five_to_eight_dist_data(file_name("crt_five_to_eight_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_crt_nine_to_ten_district_data(file_name("crt_nine_to_ten_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_ccr_elven_district_data(file_name("ccr_elven_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_naa_district_data(file_name("naa_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_elpa_district_data(file_name("elpa_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_crt_prior_district_data(file_name("crt_prior_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_grade_prior_district_data(file_name("grade_prior_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_writing_prior_district_data(file_name("writing_prior_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_naa_prior_district_data(file_name("naa_prior_school"), run_id, general_id_info)
    all_assessment_data << parser.fetch_hspe_prior_district_data(file_name("hspe_prior_school"), run_id, general_id_info)
    all_assessment_data.flatten!
    all_assessment_md5  = get_md5_hash(all_assessment_data)
    all_assessment_data = remove_md5_hash(all_assessment_data)
    [all_assessment_data, all_assessment_md5]
  end

  def fetch_demographic_data(run_id, general_id_info)
    demographic_array = parser.fetch_demographic_data(file_name("demographic"), keeper.run_id, general_id_info)
    demograph_md5     = get_md5_hash(demographic_array)
    demographic_array = remove_md5_hash(demographic_array)
    [demographic_array, demograph_md5]
  end
  
  def fetch_dicipline_data(run_id, general_id_info)
    dicipline_array = parser.fetch_dicipline_data(file_name("dicipline"), keeper.run_id, general_id_info)
    dicipline_md5   = get_md5_hash(dicipline_array)
    dicipline_array = remove_md5_hash(dicipline_array)
    [dicipline_array, dicipline_md5]
  end
      
  def fetch_financial_data(run_id, general_id_info)
    financial_array = parser.fetch_financial_data(file_name("financial"), keeper.run_id, general_id_info)
    financial_md5   = get_md5_hash(financial_array)
    financial_array = remove_md5_hash(financial_array)
    [financial_array, financial_md5]
  end
  
  def fetch_graduation_rate_data(run_id, general_id_info)
    graduation_rate_array = []
    graduation_rate_array << parser.fetch_graduation_rate_data(file_name("graduation_4_year_rate"), 4, keeper.run_id, general_id_info)
    graduation_rate_array << parser.fetch_graduation_rate_data(file_name("graduation_5_year_rate"), 5,keeper.run_id, general_id_info)
    graduation_rate_array.flatten!
    graduation_rate_md5   = get_md5_hash(graduation_rate_array)
    graduation_rate_array = remove_md5_hash(graduation_rate_array)
    [graduation_rate_array, graduation_rate_md5]
  end
      
  def fetch_drop_out_rate_data(run_id, general_id_info)
    drop_out_rate_array = parser.fetch_drop_out_rate_data(file_name("drop_out_rate"), keeper.run_id, general_id_info)
    drop_out_rate_md5   = get_md5_hash(drop_out_rate_array)
    drop_out_rate_array = remove_md5_hash(drop_out_rate_array)
    [drop_out_rate_array, drop_out_rate_md5]
  end

  def get_md5_hash(data)
    data.map{|e| e[:md5_hash]}
  end

  def remove_md5_hash(data)
    data.map{|a| a.except(:md5_hash)}
  end

end
