class Parser <  Hamster::Parser

  def csv_data(file, run_id)
    csv_data_array = []
    csv_data = JSON.parse(file)
    csv_data.each do |row|
      row_hash = {}
      row_hash[:file_name] = "Commonwealth_Of_Massachusetts_Payrollv2.csv"
      row_hash[:year] = row['year']
      row_hash[:year]= row_hash[:year] == nil ? nil : row_hash[:year]
      row_hash[:last_name] = row['name_last']
      row_hash[:first_name] = row['name_first']
      row_hash[:department_division] = row['department_division']
      row_hash[:position_title] = row['position_title']
      row_hash[:position_type] = row['position_type']
      date = row['service_end_date'].split('T')
      row_hash[:service_end_date] = date[0].to_date
      row_hash[:pay_total_actual] = row['pay_total_actual']
      row_hash[:pay_base_actual] = row['pay_base_actual']
      row_hash[:pay_buyout_actual] = row['pay_buyout_actual']
      row_hash[:pay_overtime_actual] = row['pay_overtime_actual']
      row_hash[:pay_other_actual] = row['pay_other_actual']     
      row_hash[:annual_rate] = row['annual_rate']
      row_hash[:pay_year_to_date] = row['pay_year_to_date']
      row_hash[:department_location_zip_code] = row['department_location_zip_code']
      row_hash[:contract] = row['contract']
      row_hash[:bargaining_group_no] = row['bargaining_group_no']
      row_hash[:bargaining_group_title] = row['bargaining_group_title']
      row_hash[:tans_no] = row['trans_no']
      row_hash[:dept_code] = row['chris']
      row_hash[:data_source_url] = "https://cthru.data.socrata.com/dataset/Commonwealth-Of-Massachusetts-Payrollv2/rxhc-k6iz"
      row_hash[:run_id] = run_id
      row_hash[:last_scrape_date] = Date.today
      row_hash[:next_scrape_date] = Date.today + 30
      csv_data_array << row_hash
    end
    csv_data_array
  end
end
