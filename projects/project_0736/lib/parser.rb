# frozen_string_literal: true

class Parser < Hamster::Parser

  def get_data(file, run_id)
    csv_table = CSV.parse(File.read(file), headers: true)
    headers = csv_table.headers.map(&:strip)
    csv_data = CSV.read(file, headers:headers, header_converters: :symbol, skip_blanks: true)
      csv_array = csv_data.map do |row|
        {
          fiscal_year: get_value(row[:fiscal_year]),
          first_name: get_value(row[:first]),
          middle_name: get_value(row[:m]),
          last_name: get_value(row[:last]),
          department: get_value(row[:department]),
          title: get_value(row[:title]),
          regular_earnings: get_value(row[:regular]),
          overtime_earnings: get_value(row[:overtime]),
          other_earnings: get_value(row[:other]),
          total_earnings: get_value(row[:total]),
          annual_salary: get_value(row[:annual]),
          termination: get_value(row[:termination])
        }
      end
      csv_array = insert_common_data(csv_array, run_id)
      csv_array[1..]
  end

  private

  def get_value(value)
    value.squish
  end

  def insert_common_data(csv_array, run_id)
    csv_array.each_with_index do |hash, index|
      hash[:termination] = Date.strptime(hash[:termination], "%m/%d/%Y") rescue nil
      hash = mark_empty_as_nil(hash)
      csv_array[index] = hash
      hash[:md5_hash] = create_md5_hash(hash)
      hash[:run_id] = run_id
      hash[:touched_run_id] = run_id
      hash[:data_source_url] = 'http://www.transparency.ri.gov/payroll/'
    end
    csv_array
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| (value.nil? || value.to_s.empty?) ? nil : value }
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
