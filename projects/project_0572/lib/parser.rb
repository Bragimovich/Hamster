# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_data(file, run_id)
    data_array = []
    CSV.foreach(file, headers: true) do |record|
      data_hash = {}
      record.to_hash.each do |key, val|
        key = key.downcase.split.join('_')
        data_hash[key] = val
        data_hash['run_id'] = run_id
        data_hash = mark_empty_as_nil(data_hash)
      end
      data_array << data_hash
  	end
    data_array
  end

  private

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == 'null') ? nil : value.to_s.squish}
  end
end
