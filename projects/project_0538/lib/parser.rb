class Parser < Hamster::Parser
  attr_accessor :content
  URL_GENERAL_INFO   = "https://www.alabamaachieves.org/alabama-public-and-private-school-listing/"
  URL_ENROLLMENT     = "https://reportcard.alsde.edu/SupportingData_StudentDemographics.aspx"
  URL_CAREER         = "https://reportcard.alsde.edu/SupportingData_CCRGradRate.aspx"
  URL_ACCOUNTABILITY = "https://reportcard.alsde.edu/SupportingData_Accountability.aspx"
  URL_ASSESSMENT     = "https://reportcard.alsde.edu/SupportingData_Proficiency.aspx"
  
  def initialize(file, lines_to_skip=1)
    read_csv(file, lines_to_skip)
  end

  def read_csv(file, lines_to_skip=1)
    lines = File.open(file, "r").readlines
    lines = lines[lines_to_skip..-1]
    @content = []
    lines.each do |line|
      line = line.encode("UTF-8", invalid: :replace, replace: "")
      row = CSV.parse(line.squish.gsub("=",""), quote_char: '"').flatten
      @content << row
    end
  end

  def district_data(&block)
    content.each do |arr|
      general_hash = {
        is_district:      1,
        name:             arr[1],
        phone:            arr[8],
        website:          arr[9],
        address:          arr[4],
        city:             arr[5],
        state:            arr[6],
        zip:              arr[7],
        data_source_url: URL_GENERAL_INFO
      }
      admins_hash = {
        role: 'Superintendent',
        full_name: arr[3],
        data_source_url: URL_GENERAL_INFO
      }
      general_hash = mark_empty_as_nil(general_hash)
      admins_hash = mark_empty_as_nil(admins_hash)
      district_entry = block.call(general_hash, AlGeneralInfo)
      block.call(admins_hash.merge(general_id: district_entry.id), AlAdministrators)
    end
  end

  def public_data(&block)
    content.group_by { |row| [row[0],row[1]] }.each do |names, info|
      next if names[0] == 'Other Agencies' && names[1] == 'AEA'
      admins_hashes = []
      main_arr = info.first
      low_grade, high_grade = get_grades(main_arr[9])
      general_hash = {
        system_name:      names[0],
        is_district:      0,
        name:             names[1],
        school_type:      __callee__.to_s.split('_').first,
        low_grade:        low_grade,
        high_grade:       high_grade,
        phone:            main_arr[7],
        website:          main_arr[8],
        address:          main_arr[3],
        city:             main_arr[4],
        state:            main_arr[5],
        zip:              main_arr[6],
        data_source_url:  URL_GENERAL_INFO
      }  

      info.uniq {|row| row[2]}.each do |admins_arr|
        admins_hashes << {role: 'Principal', full_name: admins_arr[2], data_source_url: URL_GENERAL_INFO} if admins_arr[2] && !admins_arr[2].squish.empty?
      end
      general_hash = mark_empty_as_nil(general_hash)
      admins_hashes = admins_hashes.map { |hash| mark_empty_as_nil(hash) }
      block.call(general_hash, admins_hashes)
    end
  end

  alias private_data public_data

  def enrollment_data(&block)
    content.each do |row|
      root_data_hash = {
        system_name:     row[1],
        school_name:     row[2],
        school_year:     "#{row.first.to_i-1}-#{row.first}",
        grade:           row[3],
        gender:          row[4],
        ethnicity:       row[5],
        sub_population:  row[6],
        data_source_url: URL_ENROLLMENT
      }

      demographics = ['Asian', 'Black or African American', "American Indian / Alaska Native", "Native Hawaiian / Pacific Islander", "White", "Two or more races"]
      values = row[8..19]
      demographic_data = []
      values.each_slice(2).with_index { |(count, percent), idx| demographic_data << root_data_hash.merge(demographic: demographics[idx], count: count, percent: percent) }
      total_hash = root_data_hash.merge(demographic: 'Total', count: row[7])
      total_hash = mark_empty_as_nil(total_hash)
      demographic_data = demographic_data.map { |hash| mark_empty_as_nil(hash) }
      block.call demographic_data.unshift(total_hash)
    end
  end

  def career_data(&block)
    content.each do |row|
      data_hash = {
        system_name:            row[2],
        school_name:            row[3],
        school_year:            "#{row.first.to_i-1}-#{row.first}",
        grade:                  row[4],
        gender:                 row[5],
        race:                   row[6],
        ethnicity:              row[7],
        sub_population:         row[1],
        student_count:          row[8],
        graduates:              row[9],
        graduation_percent:     row[10],
        ccr_attainment:         row[11],
        ccr_attainment_percent: row[12],
        data_source_url:        URL_CAREER
      }

      data_hash = mark_empty_as_nil(data_hash)
      block.call data_hash
    end
  end

  def accountability_data(&block)
    content.each do |row|
      data_hash = {
        system_name:            row[1],
        school_name:            row[2],
        school_year:            "#{row.first.to_i-1}-#{row.first}",
        grade:                  row[4],
        gender:                 row[5],
        race:                   row[6],
        ethnicity:              row[7],
        sub_population:         row[8],
        indicator:              row[3],
        score:                  row[9],
        data_source_url:        URL_ACCOUNTABILITY
      }

      data_hash = mark_empty_as_nil(data_hash)
      block.call data_hash
    end
  end

  def assessment_data(&block)
    content.each do |row|
      data_hash = {
        system_name:            row[1],
        school_name:            row[2],
        school_year:            "#{row.first.to_i-1}-#{row.first}",
        exam_name:              'Proficiency',
        subject:                row[3],
        grade:                  row[4],
        gender:                 row[5],
        race:                   row[6],
        ethnicity:              row[7],
        sub_population:         row[8],
        enrolled:               row[9],
        tested:                 row[10],
        proficient:             row[11],
        participation_rate:     row[12],
        proficient_rate:        row[13],
        data_source_url:        URL_ASSESSMENT
      }

      data_hash = mark_empty_as_nil(data_hash)
      levels_cols = row[14..]
      cols_middle = levels_cols.size / 2
      levels_count = levels_cols[0..cols_middle-1]
      levels_percent = levels_cols[cols_middle..]
      level_data = levels_count.zip(levels_percent)
      level_hashes = level_data.each_with_object([]).with_index do |(cols, arr), i|
        lvl_hash = {
          level: "Level #{i+1}",
          count: cols.first,
          percent: cols.last,
          data_source_url: URL_ASSESSMENT
        }
        arr << mark_empty_as_nil(lvl_hash)
      end
      block.call data_hash, level_hashes
    end
  end

  def hash_for_update_numbers(&block)
    content.uniq { |row| [row[0], row[2]] }.each do |row|
      hash = {
        system_name:            row[0],
        system_code:            row[1],
        school_name:            row[2],
        school_code:            row[3]
      }
      block.call mark_empty_as_nil(hash)
    end
  end

  private

  def get_grades(value)
    [value[/.+(?=-)/], value[/(?<=-).+/]] rescue [nil, nil]
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : ((value.to_s.valid_encoding?)? value.to_s.squish : value.to_s.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '').squish)}
  end
end
