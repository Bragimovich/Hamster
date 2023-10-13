require_relative '../lib/common_methods'

module LaEnrollment

  include CommomMethods

  def parsing_enrollment(path, file, la_info_data, link)
    data_array = []
    xlsx_file = Roo::Spreadsheet.open(path) rescue nil
    xlsx_file = Roo::Excel.new(file) if xlsx_file.nil? rescue nil
    return [] if xlsx_file.nil?

    sheets_names = xlsx_file.sheets
    return [] if sheets_names.nil? or sheets_names.empty?

    school_year = path.split('/')[-2].gsub('_', '-')
    sheets_names.each do |sheet_name|
      year, month, number = '', '', ''
      start_index = 0
      demographic_array = []
      group_array = []
      flag, insert_once, check_multiply = true, true, true
      xlsx_file.sheet(sheet_name).each do |row|
        if row.to_s.downcase.include? 'students by gender'
          array = row[row.find_index('Students by Gender')-1..] rescue nil
          array = row[row.find_index('Students By Gender')-1..] if array.nil?
          group_array = set_group_array(array)
        end
        if row.to_s.include? 'Total Enrollment' or row.to_s.include? 'Grade 1'
          start_index = row.find_index('% Female')
          start_index = row.find_index('Female') if start_index.nil?
          demographic_array = row.reject { |e| e.nil? }
          demographic_array.insert(0, 'Total Enrollment') unless demographic_array[0].downcase.to_s.include? 'total'
        end
        if !row[0].nil? and row.to_s.include? 'For Total'
          data = row[0].split('-').last.split(',')
          year = data.last.squish
          month = data.first.squish
        end
        @common_hash = enrollment_common_data_hash(school_year, year, month, link)
        if !row[0].nil? and row[0] == '001'
          flag = false
        end
        next if flag or row[0].nil?

        if row[0].to_s.length < 4
          number = row[0]
        end
        @general_id, la_info_data = get_general_id(la_info_data, row, number)
        updated_row = row[(start_index - 1)..]
        if path.end_with? '.xls' and insert_once
          demographic_array.insert(11, group_array[11])
          insert_once = false
        end
        check_multiply = false if updated_row[1].to_i > 1
        updated_row.each_with_index do |record, idx|
          data_array << get_enrollment_hash(updated_row[idx], demographic_array[idx], group_array[idx], check_multiply)
        end
      end
    end
    data_array
  end

  private

  def set_group_array(row)
    row.each_with_index do |value, index|
       if value.nil?
         row[index] = row[index -1]
       end
    end
    row
  end

  def enrollment_common_data_hash(school_year, year, month, link)
    data_hash = {}
    data_hash[:school_year] = school_year
    data_hash[:year] = year
    data_hash[:month] = month
    data_hash[:data_source_url] = link[0]
    data_hash
  end

  def get_enrollment_hash(data, demographic, group, check_multiply)
    hash = @common_hash.clone
    hash[:demographic] = demographic
    hash[:general_id] = @general_id
    hash[:group] = group
    percentage, number = get_data_value(data, group, demographic, check_multiply)
    hash[:percent] = percentage
    hash[:count] = number
    hash = commom_hash_info(hash)
    hash
  end
end

def get_data_value(data, group, demographic, check_multiply)
  if (!group.nil? and group.include? '%') or (!demographic.nil? and (demographic.include? '%' or demographic.downcase.include? 'male' or demographic.downcase.include? 'female'))
    percentage = ''
    if data.to_s.include? '%'
       percentage = data
    else
      percentage = check_multiply ? "#{data*100}" : "#{data}%"
    end
    return [percentage, nil]

  end
  [nil, data]
end
