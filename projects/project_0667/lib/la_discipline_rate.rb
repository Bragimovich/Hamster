require_relative '../lib/common_methods'

module LaDisciplineRate
  include CommomMethods

  def parsing_discipline_rate(path, file, la_info_data, link)
    data_array = []
    xlsx_file = Roo::Spreadsheet.open(path) rescue nil
    return [] if xlsx_file.nil?

    sheet_name = xlsx_file.sheets.select { |e| e == 'Distict' }[0]
    sheet_name = xlsx_file.sheets.select { |e| e == 'District' }[0] if sheet_name.nil?
    sheet_name = xlsx_file.sheets.select { |e| e == 'LEA' }[0] if sheet_name.nil?
    return [] if sheet_name.nil?

    year = ''
    flag = true
    xlsx_file.sheet(sheet_name).each_with_index do |row, index|
      year = row[0].split.first if index == 1
      flag = false if row[0] == '001' or row[1] == '001'
      next if flag or row[0].nil? or row[0].to_s.include? '*' or row[0].to_s.include? 'is'

      if path.include? '8951891f_4.xlsx'
        general_id, la_info_data = get_general_id(la_info_data, row[1..])
      else
        general_id, la_info_data = get_general_id(la_info_data, row)
      end
      row.insert(2, nil) if row.count == 14
      row = row[1..] if row.count == 16
      data_array << create_discipline_rate_hash(year, general_id, row, link)
    end
    data_array
  end

  private

  def create_discipline_rate_hash(year, general_id, row, link)
    hash = {}
    hash[:school_year] = year
    hash[:general_id] = general_id
    hash[:data_source_url] = link[0]
    hash[:cumulative_enrollment] = row[2]
    hash[:in_school_suspension_count] = row[3]
    hash[:in_school_suspension_rate] = convert_to_percentage(row[4])
    hash[:out_school_suspension_count] = row[5]
    hash[:out_school_suspension_rate] = convert_to_percentage(row[6])
    hash[:in_school_expulsion_count] = row[7]
    hash[:in_school_expulsion_rate] = convert_to_percentage(row[8])
    hash[:out_school_expulsion_count] = row[9]
    hash[:out_school_expulsion_rate] = convert_to_percentage(row[10])
    hash[:alternative_suspension_count] = row[11]
    hash[:alternative_suspension_rate] = convert_to_percentage(row[12])
    hash[:alternative_expulsion_count] = row[13]
    hash[:alternative_expulsion_rate] = convert_to_percentage(row[14])
    commom_hash_info(hash)
  end

end
