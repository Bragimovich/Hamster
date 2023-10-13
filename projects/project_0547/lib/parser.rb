# frozen_string_literal: true

class Parser < Hamster::Parser

  def process_file(file, run_id)
    hash_array = []
    begin
      all_data = fetch_json(file)
    rescue StandardError => e
      return hash_array
    end
    all_data.each do |data|
      data.delete("ids")
      data["entity"] =  data.delete "entity_name"
      data = mark_empty_as_nil(data)
      data[:run_id] = run_id
      data[:last_scrape_date] = Date.today
      data[:next_scrape_date] = Date.today.next_year
      hash_array << data
    end
    hash_array
  end

  private

  def fetch_json(response)
    JSON.parse(response)
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end
end
