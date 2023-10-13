require_relative '../lib/keeper'

module CommomMethods

  def initialize
    @keeper = Keeper.new
  end

  def commom_hash_info(hash)
    hash[:md5_hash] = create_md5_hash(hash)
    hash[:run_id] = @keeper.run_id
    hash[:touched_run_id] = @keeper.run_id
    hash
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def insert_general_id(row, la_info_data)
    id = nil
    if row[0].length > 3
      district_id = la_info_data.select{|e| e[:number] == row[0][0..2]}[0][:id] rescue nil
      district_id = insert_la_info_data(row, nil, 1) if district_id.nil?
      id, la_info_data = insert_la_info_data(row, district_id, 0)
    else
      id, la_info_data = insert_la_info_data(row, nil, 1)
    end
    [id, la_info_data]
  end

  def convert_to_percent(value)
    (value.to_s.include? '0.') ? "#{(value*100)}%" : value
  end

  private

  def insert_la_info_data(row, number, is_district)
    hash = {}
    hash[:number] = is_district == 1 ? row[0][0..2] : row[0]
    hash[:name] = row[1]
    district_id = @keeper.get_district_id(number) if is_district == 0
    hash[:district_id] = district_id if is_district == 0
    hash[:is_district] = is_district
    hash[:md5_hash] = create_md5_hash(hash)
    hash[:run_id] = 1
    @keeper.add_district(hash)
  end

  def get_general_id(la_info_data, row, number = nil)
    general_id = la_info_data.select { |e| e[:number].downcase == row[0].downcase }[0][:id] rescue nil
    general_id, la_info_data = insert_la_info_data(row, nil, 1) if general_id.nil? and row[0].to_s.length < 4
    general_id, la_info_data = insert_la_info_data(row, number, 0) if general_id.nil? and row[0].to_s.length > 3
    [general_id, la_info_data]
  end

end
