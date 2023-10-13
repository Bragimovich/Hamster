require_relative '../lib/common_methods'
require_relative '../lib/keeper'

module LaAssessmentKgEntry
  include CommomMethods

  def parsing_kindergarten(path, file, la_info_data, link)
    data_array = []
    domain_array = []
    number = ''
    xlsx_file = Roo::Spreadsheet.open(path) rescue nil
    return [] if xlsx_file.nil?

    sheet_name = xlsx_file.sheets.select { |e| e == 'by LEA and Subgroup' }[0]
    return [] if sheet_name.nil?

    year = ''
    dimension_array = ['Approaches to Learning & Self Regulation', 'Social and Emotional Development', 'Language and Literacy Development', 'Cognition: Math', 'Physical Development']
    xlsx_file.sheet(sheet_name).each_with_index do |row, index|
       if row.to_s.include? 'Overall Domain'
          domain_array = row.reject { |e| e.nil? }
       end
      year = row[0].split.first if index == 1
      next if index < 7

      if row[0].length < 4
        number = row[0]
      end
      @general_id, la_info_data = get_general_id(la_info_data, row)
      subgroup = row[2]
      total_records_submitted = row[3]
      result_row = get_data_array(row)
      dimension_ind = -1
      @commom_hash = kindergarten_commom_data_hash(year, subgroup, total_records_submitted, link)
      result_row.each_with_index do |record, index|
        dimension_ind = dimension_ind+=1 if record.count == 4
        data_array << get_kindergarten_hash(domain_array[index], dimension_array[dimension_ind], record)
      end
      data_array << get_kindergarten_hash('Total', 'Total', [row.last])
    end
    data_array
  end

  private

  def kindergarten_commom_data_hash(year, subgroup, total_records_submitted, link)
    hash = {}
    hash[:school_year] = year
    hash[:subgroup] = subgroup
    hash[:total_records_submitted] = total_records_submitted
    hash[:data_source_url] = link[0]
    hash
  end

  def get_data_array(row)
    result_row = []
    result_row = [row[4..7]]
    row[8..19].each_slice(3) { |data| result_row << data }
    result_row = result_row + [row[20..23]]
    row[24..38].each_slice(3) { |data| result_row << data }
    result_row = result_row + [row[39..42]]
    row[43..72].each_slice(3) { |data| result_row << data }
    result_row = result_row + [row[73..76]]
    row[77..88].each_slice(3) { |data| result_row << data }
    result_row = result_row + [row[89..92]]
    row[93..104].each_slice(3) { |data| result_row << data }
    result_row
  end

  def get_kindergarten_hash(domain, dimension, data)
    data_hash = @commom_hash.clone
    data_hash[:general_id] = @general_id
    data_hash[:domain] = domain
    data_hash[:dimension] = dimension
    data_hash[:approaching_expectations] = data.count > 1 ? data[0] : nil
    data_hash[:meeting_expectations] = data.count > 1 ? data[1] : nil
    data_hash[:exceeding_expectations] = data.count > 1 ? data[2] : nil
    data_hash[:meeting_exceeding_expectations] = data.count > 1 ? data[3] : data[0]
    data_hash = commom_hash_info(data_hash)
    data_hash
  end
end
