# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_json(response)
    JSON.parse(response.force_encoding("utf-8"))
  end

  def parse(data, year, run_id, department)
    hash_array = []
    data["records"].each do |row|
      data_hash = {}
      data_hash["name"] = row['full_name']
      
      data_hash["first_name"] = row['first_name']
      data_hash["last_name"], data_hash["middle_name"] = get_middle_names(row['last_name'].gsub('-', ' '))
      data_hash["agency"] = row["org1"]
      data_hash["job_title"] = row['position_title']
      data_hash["total_pay"] = convert_to_decimal(row['pay_total_actual'])

      data_hash["salaries_and_wages"] = convert_to_decimal(row['pay1'])
      data_hash["overtime_pay"] = convert_to_decimal(row['pay2'])
      data_hash["other_pay"] = convert_to_decimal(row['pay3'])
      data_hash["non_retirement_fringe"] = convert_to_decimal(row['employee_table_field9'])
      data_hash["sers_retirement_fringe"] = convert_to_decimal(row['employee_table_field10'])
      data_hash["arp_retirement_fringe"] = convert_to_decimal(row['employee_table_field11'])
      data_hash["year"] = year.to_i
      data_hash = mark_empty_as_nil(data_hash)
      data_hash["scrape_frequency"] = "Yearly"
      data_hash["last_scrape_date"] = Date.today
      data_hash["next_scrape_date"] = Date.today.next_year
      data_hash["run_id"] = run_id
      data_hash["touched_run_id"] = run_id
      hash_array << data_hash
    end
    hash_array
  end

  private

  def convert_to_decimal(val)
    val.to_s.gsub(",","").gsub("$","").to_f
  end

  def get_middle_names(name)
    if name.split.count >= 2
      return [name.split.first.strip, name.split[1..-1].join(" ")]
    end
    [name.split.first.strip, '']
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value}
  end
end
