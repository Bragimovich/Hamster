require_relative '../lib/common_methods'

module LaAssessmentLeap
  include CommomMethods

  def parsing_assessment(path, file, la_info_data, link)
    data_array = []
    @assessment_link = link
    @school_year = path.split('/')[-2].gsub('_', '-')
    xlsx_file = Roo::Spreadsheet.open(path) rescue nil
    return [] if xlsx_file.nil?

    sheets_name = xlsx_file.sheets
    sheets_name.each do |sheet|
      data_array << get_assessment_data(sheet, xlsx_file, la_info_data) unless sheet == 'High School'
      data_array << get_final_year_assessment_data(sheet, xlsx_file, la_info_data) if sheet == 'High School'
    end
    data_array.flatten
  end

  private

  def get_assessment_data(sheet, xlsx_file, la_info_data)
    data_array = []
    subject_array = ['English Language Arts', 'Mathematics', 'Science', 'Social Studies']
    number = ''
    flag = true
    xlsx_file.sheet(sheet).each do |row|
      flag = false if !row[0].nil? and (row[0] == 'STATE' or row[0] == 'LA')
      next if flag

      if row[0].length < 4
        number = row[0].to_s
      end
      @general_id, la_info_data = get_general_id(la_info_data, row)
      row = row[3..] if row.count == 18 or row.count == 33
      row = row[2..] if row.count == 17 or row.count == 32
      result_row = []
      if row.count == 15
        row.each_slice(5) { |data| result_row << data }
        result_row.each_with_index do |record, index|
          index = index + 1 if index == 2
          data_array << get_assessment_hash(sheet, subject_array[index], record)
        end
      end
      if row.count == 30
        row[0..27].each_slice(7) { |data| result_row << data }
        result_row.each_with_index do |record, index|
          data_array << get_assessment_hash(sheet, subject_array[index], record)
        end
        data_array << get_assessment_hash(sheet, 'Total', row[28..29])        
      end
    end
    data_array
  end

  def get_final_year_assessment_data(sheet, xlsx_file, la_info_data)
    data_array = []
    subject_array = ['English I', 'English II', 'Algebra', 'Geometry', 'Biology', 'U.S. History']
    number = ''
    flag = true
    xlsx_file.sheet(sheet).each do |row|
      flag = false if !row[0].nil? and (row[0] == 'STATE' or row[0] == 'LA')
      next if flag

     if row[0].length < 4
      number = row[0] 
     end
      @general_id, la_info_data = get_general_id(la_info_data, row)
      row = row[3..] if row.count == 32 or row.count == 50
      row = row[2..] if row.count == 27
      result_row = []
      if row.count == 29
        row.each_slice(6) { |data| result_row << data }
        result_row.last << nil
        result_row = result_row.map { |e| e[..-2]}
        result_row.each_with_index do |record, index|
          index = index + 1 if index == 4
          data_array << get_assessment_hash(sheet, subject_array[index], record)
        end
      end
      if row.count == 25
        row.each_slice(5) { |data| result_row << data }
        result_row.each_with_index do |record, index|
          index = index + 1 if index == 4
          data_array << get_assessment_hash(sheet, subject_array[index], record)
        end
      end

      if row.count == 47
        row.each_slice(8) { |data| result_row << data }
        result_row.last << nil
        result_row = result_row.map { |e| e[..-2] }
        result_row.each_with_index do |record, index|
          data_array << get_assessment_hash(sheet, subject_array[index], record)
        end
      end
    end
    data_array
  end

  def get_assessment_hash(sheet, subject, data)
    data_hash = {}
    flag = true if subject == 'Total'
    data_hash[:school_year] = @school_year
    data_hash[:general_id] = @general_id
    data_hash[:grade] = sheet
    data_hash[:data_source_url] = @assessment_link[0]
    data_hash[:subject] = subject
    data_hash[:advanced_percent] = flag ? nil : data[0].to_s.squish
    data_hash[:mastery_percent] = flag ? nil : data[1].to_s.squish
    data_hash[:basic_percent] = flag ? nil : data[2].to_s.squish
    data_hash[:approaching_basic_percent] = flag ? nil : data[3].to_s.squish
    data_hash[:unsatisfactory_percent] = flag ? nil : data[4].to_s.squish
    data_hash[:expected_to_participate] = flag ? data[0] : data[5]
    participation_rate = flag ? data[1] : data[6]
    if participation_rate.nil? or participation_rate == 'NR' or participation_rate.to_s.include? '%'
      data_hash[:participation_rate] = participation_rate
    else
      data_hash[:participation_rate] = "#{participation_rate*100}%"
    end
    data_hash = commom_hash_info(data_hash)
    data_hash
  end

end
