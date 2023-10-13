require_relative '../lib/common_methods'

module LaDisciplineReason
  include CommomMethods

  def discipline_reason(path, file, la_info_data, link)
    data_array = []
    xlsx_file = Roo::Spreadsheet.open(path) rescue nil
    return [] if xlsx_file.nil?

    sheets_name = xlsx_file.sheets.select { |e| e == 'Primary Reason'}[0]
    return [] if sheets_name.nil?

    year = ''
    xlsx_file.sheet(sheets_name).each_with_index do |row, index|
      year = row[0].split.first if index == 1
      next if index < 5 or row[0].nil? or row[0].to_s.include? '*'

      general_id = la_info_data.select { |e| e[:number].downcase == 'state' }[0][:id] rescue nil
      data_array <<  create_reason_hash(general_id, row, link, year)
    end
    data_array
  end

  def create_reason_hash(general_id, row, link, year)
    data_hash = {}
    data_hash[:general_id] = general_id
    data_hash[:school_year] = year
    data_hash[:data_source_url] = link[0]
    data_hash[:primary_reason_code] = row[0]
    data_hash[:primary_reason_description] = row[1]
    data_hash[:in_school_suspension] = row[2]
    data_hash[:out_school_suspension] = row[3]
    data_hash[:in_school_expulsion] = row[4]
    data_hash[:out_school_expulsion] = row[5]
    data_hash[:rank] = row[6]
    commom_hash_info(data_hash)
  end
end
