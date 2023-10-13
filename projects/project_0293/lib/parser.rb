class Parser <  Hamster::Parser

  def csv_data(file, run_id)
    csv_array = []
    md5_hash_array = []
    csv_data = json_parse(file)
    csv_data.each do |row|
      row_hash = {}
      row_hash[:year]                 = year_extract(row['cdc_case_earliest_dt'])
      row_hash[:cdc_case_earliest_dt] = formating_dates(row['cdc_case_earliest_dt'])
      row_hash[:cdc_report_date]      = formating_dates(row['cdc_report_dt'])
      row_hash[:pos_spec_date]        = formating_dates(row['pos_spec_dt'])
      row_hash[:onset_date]           = formating_dates(row['onset_dt'])
      row_hash[:current_status]       = row_key_value(row, 'current_status')
      row_hash[:sex]                  = row_key_value(row, 'sex')
      row_hash[:age_group]            = row_key_value(row, 'age_group')
      row_hash[:race_and_ethnicity]   = row_key_value(row, 'race_ethnicity_combined')
      row_hash[:hospital]             = row_key_value(row, 'hosp_yn')
      row_hash[:icu]                  = row_key_value(row, 'icu_yn')
      row_hash[:death]                = row_key_value(row, 'death_yn')
      row_hash[:medical_condition]    = row_key_value(row, 'medcond_yn')
      row_hash[:md5_hash]             = create_md5_hash(row_hash)
      md5_hash_array << row_hash[:md5_hash]
      row_hash.delete(:md5_hash)
      row_hash[:run_id]               = run_id
      row_hash[:touch_run_id]         = run_id
      row_hash[:last_scrape_date]     = Date.today
      row_hash[:next_scrape_date]     = Date.today.next_month 
      row_hash[:expected_scrape_frequency] = Date.today.next_month
      csv_array << row_hash
    end
    [csv_array , md5_hash_array]
  end

  def json_parse(response)
    JSON.parse(response) 
  end

  private

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.each_value do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def row_key_value(row,key)
    key_value = row.select{|e| e.include? key}
    key_value.values.join
  end

  def formating_dates(date)
   date.to_date unless date.nil?
  end

  def year_extract(date)
    date = date.split('-')
    date[0]
  end
end
