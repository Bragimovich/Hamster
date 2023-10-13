require_relative '../models/us_assisted_housing'
require_relative '../models/us_assisted_housing_runs'
require_relative '../models/us_assisted_housing_files'

class Keeper
  attr_reader :run_id
  HEADER_COLUMNS = [
    'quarter','gsl' ,'states' ,'entities' ,'sumlevel' ,'program_label' ,'program' ,'sub_program' ,'name' ,'code' ,'total_units' ,'pct_occupied' ,'number_reported' ,'pct_reported' ,'months_since_report' ,'pct_movein' ,'people_per_unit' ,'people_total' ,'rent_per_month' ,'spending_per_month' ,'hh_income' ,'person_income' ,'pct_lt5k' ,'pct_5k_lt10k' ,'pct_10k_lt15k' ,'pct_15k_lt20k' ,'pct_ge20k' ,'pct_wage_major' ,'pct_welfare_major' ,'pct_other_major' ,'pct_median' ,'pct_lt50_median' ,'pct_lt30_median' ,'pct_2adults' ,'pct_1adult' ,'pct_female_head' ,'pct_female_head_child' ,'pct_disabled_lt62' ,'pct_disabled_ge62' ,'pct_disabled_all' ,'pct_lt24_head' ,'pct_age25_50' ,'pct_age51_61' ,'pct_age62plus' ,'pct_age85plus' ,'pct_minority' ,'pct_black_nonhsp','pct_native_american_nonhsp', 'pct_asian_pacific_nonhsp' ,'pct_white_nothsp','pct_black_hsp','pct_wht_hsp','pct_oth_hsp','pct_hispanic','pct_multi','months_waiting' ,'months_from_movein' ,'pct_utility_allow' ,'ave_util_allow' ,'pct_bed1' ,'pct_bed2' ,'pct_bed3' ,'pct_overhoused' ,'tpoverty' ,'tminority' ,'tpct_ownsfd' ,'fedhse' ,'cbsa' ,'place' ,'latitude' ,'longitude' ,'state' ,'pha_total_units' ,'ha_size','data_source_url'
  ]
  def initialize
    super
    @run_object = RunId.new(UsAssistedHousingRun)
    @run_id = @run_object.run_id
  end

  def store(row)
    row = check_capitalized_columns(row)
    data = row.slice(*HEADER_COLUMNS)
    
    md5_hash = MD5Hash.new(columns: HEADER_COLUMNS)
    data = remove_unwanted_chars(data)
    data.merge!(run_id: run_id,touched_run_id: run_id, md5_hash: md5_hash.generate(data))
    UsAssistedHousing.insert(data)
  end

  def check_capitalized_columns(row)
    HEADER_COLUMNS.each do |col|
      # if unable to locate column then look for capitalized column
      if row[col].nil?
        row[col] = row[col.capitalize].to_s unless row[col.capitalize].nil?
      end
    end

    row
  end

  def file_info(data)
    data.merge!(run_id: run_id)
    md5_hash = MD5Hash.new(columns: [:data_source_url,:data_source_file,:run_id])
    data.merge!(md5_hash: md5_hash.generate(data))
    UsAssistedHousingFile.find_or_create_by(data)
  end

  def remove_unwanted_chars(hash)
    # replace empty values with nil, NA with nil
    hash.each do |k, v|
       if v.kind_of?(String)
        hash[k] = nil if v.empty?
        hash[k] = nil if v == 'NA'
       end
    end

    hash
  end

  def finish
    @run_object.finish
  end
end
