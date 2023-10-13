# frozen_string_literal: true

class Parser < Hamster::Parser

  def initialize
    super
    @keeper = Keeper.new
  end

  def parse_data(file)
    data_array = []
    md5_array = []
    CSV.foreach(file, headers: true, encoding: 'ISO-8859-1', liberal_parsing: true) do |row|
      begin
        data_hash = row.to_hash
        md5_hash = create_md5_hash(data_hash)
        data_hash = data_hash.merge('md5_hash' => md5_hash)
        data_hash = data_hash.merge('run_id' => keeper.run_id)
        data_hash = data_hash.merge('touched_run_id' => keeper.run_id)
        data_hash = data_hash.merge('data_source_url' => 'https://www.transportation.gov/mission/open/gis/national-address-database/national-address-database-nad-disclaimer')
        data_hash = get_required_date_formats(data_hash)
        data_array << data_hash
        md5_array << md5_hash
        file_handling("#{row}", 'a', 'processed_lines')
      rescue
        file_handling("#{row}", 'a', 'false_lines')
        next
      end
      if (data_array.count == 5000)
        data_array = data_array.reject{ |e| e.empty? }
        md5_array = md5_array.reject{ |e| e.empty? }
        keeper.insert_records(data_array)
        keeper.update_touched_run_id(md5_array)
        data_array = []
        md5_array = []
      end
    end
    data_array = data_array.reject{ |e| e.empty? }
    md5_array = md5_array.reject{ |e| e.empty? }
    keeper.insert_records(data_array)
    keeper.update_touched_run_id(md5_array) unless md5_array.empty?
  end

  private

  attr_reader :keeper

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def get_required_date_formats(data_hash)
    data_hash.each do |key,value|
      if (value.is_a?(String) && value.match(/\d{1,2}\/\d{1,2}\/\d{4}/))
        begin
          data_hash[key] = Date.strptime(value, '%m/%d/%Y').strftime('%Y/%m/%d')
        rescue
          data_hash[key] = value
        end
      end
    end
  end

  def file_handling(content, flag, file_name)
    list = []
    File.open("#{storehouse}store/#{file_name}.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s)
    end
    list unless list.empty?
  end

end
