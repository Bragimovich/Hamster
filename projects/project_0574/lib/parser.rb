class Parser < Hamster::Parser

  def json_response(response)
    JSON.parse(response)
  end

  def file_process(file , run_id)
    data       = json_response(file)
    data_array = []
    data["salaryArray"].each do |row|
      data_hash = {}
      data_hash[:state]                = "Kentucky"
      data_hash[:year]                 =  Date.today.year
      data_hash[:full_name]            =  row_key_value(row, "fullName")
      data_hash[:first_name]           =  row_key_value(row, "firstName")
      data_hash[:last_name]            =  row_key_value(row, "lastName")
      data_hash[:middle_name]          =  row_key_value(row, "middleInitial")
      data_hash[:branch]               =  row_key_value(row, "branchName")
      data_hash[:cabinet]              =  row["cabinet"]
      data_hash[:title]                =  row_key_value(row, "title")
      data_hash[:department]           =  row_key_value(row, "department")
      data_hash[:salary]               =  row_key_value(row, "totalSalary")
      data_hash                        =  mark_empty_as_nil(data_hash)
      data_hash[:last_scrape_date]     =  Date.today
      data_hash[:next_scrape_date]     =  Date.today.next_year
      data_hash[:run_id]               =  run_id
      data_array << data_hash
    end
    data_array
  end

  private

  def row_key_value(row,key)
    key_value = row.select{|e| e.include? key}
    key_value.values.join.squish
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s == "" || value == 'null' ? nil : value }
  end

end
