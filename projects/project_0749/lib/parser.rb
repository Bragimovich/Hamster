# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_data(file, run_id, data_source_url)
    md5_array = []
    data_array = []
    rows = CSV.parse(File.read(file, encoding: "ISO-8859-1"), headers: true, liberal_parsing: true) rescue nil
    return [[],[]] if (rows.nil?)
    rows.each do |row|
      begin
        data_hash = row.to_hash.reject{|e| e.nil?}.transform_keys{ |key| key.gsub(' ', '_').underscore }
        data_hash = mark_empty_as_nil(data_hash)
        md5_hash = create_md5_hash(data_hash)
        data_hash = data_hash.merge('md5_hash' => md5_hash)
        data_hash = data_hash.merge('run_id' => run_id)
        data_hash = data_hash.merge('touched_run_id' => run_id)
        data_hash = data_hash.merge('data_source_url' => data_source_url)
        data_array << change_date_format(data_hash)
        md5_array << md5_hash
      rescue
        next
      end
    end
    [data_array, md5_array]
  end

  private

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.to_s)
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def change_date_format(hash)
    hash.each do |key, value|
      hash[key] = nil if checkNil?(value)
      hash[key] = Date.strptime(value, '%m/%d/%Y') if key.to_s.include?('_date')
    end
  end

  def checkNil?(value)
    arr = ["na", "n/", "n/a", "unknown", "none", "not available", "-", "?", "--", "??", "`", ",", ""]
    arr.include?(value.to_s.delete(' ').downcase)
  end
  
end
