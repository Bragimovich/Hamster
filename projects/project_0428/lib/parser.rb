class Parser <  Hamster::Parser

  def main_page_body(response)
    page_scraper = parsing(response.body)
  end

  def parse_row(row)
    CSV.parse_line(row)
  end

  def get_data(data_row, idx, headers, data_value)
    hash = {}
    headers.each_with_index do |title, title_idx|
      next if ['name', "city","stabbr","cty_name"].include?(title)
      hash[title] = data_value[title_idx]
    end
    transform(hash)
  end

  def county_state(file_data, data_hash, run_id, year)
    first_two_digit = data_hash[:zip_code].to_s[0, 2]
    last_three_digit = data_hash[:zip_code].to_s[-3, 3]
    result = file_data.select{|e| (e.include? (first_two_digit)) && (e.include? (last_three_digit))}
    if result.empty?
      data_hash[:county] = nil
      data_hash[:state] = nil
    end
    unless result.empty?
      data = parse_row(result[0])
      data_hash[:county] = data[-1].split(",")[0]
      data_hash[:state]  = data[-1].split(",")[1].squish
    end
    data_hash[:year] = year
    data_hash[:run_id] = run_id
    data_hash
  end

  private

  def transform(hash)
    mappings ={
      "zip" => :zip_code,
      "naics" => :naics_industry_code,
      "est"=> :num_establishments_total,
      "n<5" => :num_establishments_1_to_4_employees,
      "n5_9" => :num_establishments_5_to_9_employees,
      "n10_19" => :num_establishments_10_to_19_employees,
      "n20_49" => :num_establishments_20_to_49_employees,
      "n50_99" => :num_establishments_50_to_99_employees,
      "n100_249" =>  :num_establishments_100_to_249_employees,
      "n250_499" => :num_establishments_250_to_499_employees,
      "n500_999" => :num_establishments_500_to_999_employees,
      "n1000" => :num_establishments_1000_or_more_employees
    }
    new_hash = hash.transform_keys { |k| mappings[k.to_s] }.compact
    new_hash.delete(nil)
    new_hash
  end
end
