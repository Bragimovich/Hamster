class Parser < Hamster::Parser

  def get_link(main_page)
    page = fetch_nokogiri_response(main_page)
    page.css("a.btn-success").map{|a| a['href']}.first
  end

  def get_data(csv,run_id,file_name)
    doc = File.read(csv[0])
    all_data = CSV.parse(doc)
    data_array = []
    all_data.each_with_index do |row,index|
      next if index == 0
      data_hash = {}
      data_hash [:agency]            = row[0]
      data_hash [:budget_entity]     = row[1]
      data_hash [:position_num]      = row[2]
      data_hash [:last_name]         = row[3]
      data_hash [:first_name]        = row[4]
      data_hash [:middle_name]       = row[5]
      data_hash [:employee_type]     = row[6]
      data_hash [:full_or_part_time] = row[7]
      data_hash [:class_code]        = row[8]
      data_hash [:class_title]       = row[9]
      data_hash [:state_hire_date]   = row[10]
      data_hash [:annual_salary]     = get_salary_and_ops(row[11])
      data_hash [:ops_hourly_rate]   = get_salary_and_ops(row[12])
      data_hash [:last_scrape_date]  = Date.today
      data_hash [:next_scrape_date]  = Date.today.next_year
      data_hash [:run_id]            = run_id
      data_hash [:file_name]         = file_name
      data_hash [:year]              = Date.today.year
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array
  end

  private

  def get_salary_and_ops(row)
    return nil if row.nil?
    row.split("$").last.strip.split(',').join()
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value}
  end

  def fetch_nokogiri_response(page)
    Nokogiri::HTML(page.body.force_encoding("utf-8"))
  end
  
end
