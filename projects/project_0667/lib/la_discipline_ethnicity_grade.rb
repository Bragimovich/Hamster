require_relative '../lib/common_methods'

module LaDisciplineEthnicityGrade
  include CommomMethods

  def parsing_discipline_subgroup(path, file, la_info_data, link)
    data_array = []
    xlsx_file = Roo::Spreadsheet.open(path) rescue nil
    return [] if xlsx_file.nil?

    sheets_name = xlsx_file.sheets.reject { |e| e == 'Primary Reason' }
    year = ''
    sheets_name.each do |sheet|
      xlsx_file.sheet(sheet).each_with_index do |row, index|
        year = row[0].split.first if index == 1
        next if index < 5 or row[0].nil? or row[0].to_s.include? '*'
        if path.include? '8b256318_2.xlsx'
          general_id, la_info_data = get_general_id(la_info_data, row[1..])
        else
          general_id, la_info_data = get_general_id(la_info_data, row)
        end
        row.insert(5, nil) if row.count == 13
        row = row[1..] if row.count == 15
        data_array << create_grade_hash(year, general_id, sheet, row, link)
      end
    end
    data_array
  end

  private

  def create_grade_hash(year, general_id, sheet, row, link)
    hash = {}
    hash[:school_year] = year
    hash[:general_id] = general_id
    hash[:data_source_url] = link[0]
    hash[:group] = sheet
    hash[:subgroup] = row[4]
    hash[:total_students] = row[5]
    hash[:in_school_suspension_count] =  row[6]
    hash[:in_school_suspension_rate] = convert_to_percent(row[7])
    hash[:out_school_suspension_count] = row[8]
    hash[:out_school_suspension_rate] = convert_to_percent(row[9])
    hash[:in_school_expulsion_count] = row[10]
    hash[:in_school_expulsion_rate] = convert_to_percent(row[11])
    hash[:out_school_expulsion_count] = row[12]
    hash[:out_school_expulsion_rate] = convert_to_percent(row[13])
    commom_hash_info(hash)
  end

end
