# frozen_string_literal: true

class Parser < Hamster::Parser
  def fetch_json(data)
    JSON.parse(data)
  end

  def parse_data(raw_data, run_id)
    data_array = []
    raw_data['rows'].each do |row|
      data_hash = {}
      data_hash[:year] = row[0]['value'].to_i
      data_hash[:first_name], data_hash[:middle_name], data_hash[:last_name], data_hash[:full_name] = fetch_name(row)
      data_hash[:agency]           = row[3]['value']
      data_hash[:position]         = row[4]['value']
      data_hash[:salary]           = row[5]['value'].gsub('$', '').gsub(',', '').to_i
      data_hash                    = mark_empty_as_nil(data_hash)
      data_hash[:run_id]           = run_id
      data_hash[:last_scrape_date] = Date.today
      data_hash[:next_scrape_date] = Date.today + 365
      data_array << data_hash
    end
    data_array
  end

  private

  def fetch_name(row)
    name = row[1]['value'].split
    first_name = name.first.squish
    middle_name = name[1..].join(' ').squish
    last_name = row[2]['value'].squish
    full_name = "#{first_name} #{middle_name} #{last_name}".squish
    [first_name, middle_name, last_name, full_name]
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end
end
