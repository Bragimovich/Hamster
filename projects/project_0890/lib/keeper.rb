# require model files here
require_relative '../models/nc_assessment_run'
require_relative '../models/nc_general_info'
require_relative '../models/nc_assessment'
require_relative '../models/nc_assessment_act'
require_relative '../models/nc_assessment_ap_sat'
require_relative '../models/nc_finaces_expenditure'
require_relative '../models/nc_finances_salary'
require_relative '../models/nc_usa_raw'
require 'roo'
require 'roo-xls'
class Keeper < Hamster::Keeper
  attr_reader :run_id

  def initialize
    super
    @run_object = RunId.new(NcAssessmentRun)
    @run_id = @run_object.run_id
    @buffer = []
  end

  def store(hash_data)
    # write store logic here
  end

  def store_general_info
    manual_data = []
    manual_data << {is_district: nil, number: nil, name: 'United States', type: 'All Students', data_source_url: "manual value"}
    manual_data << {is_district: nil, number: nil, name: 'United States', type: 'Public School Students', data_source_url: "manual value"}
    manual_data << {is_district: nil, number: 0, name: 'North Carolina', type: 'State', state: 'NC', data_source_url: "manual value"}
    manual_data << {is_district: nil, number: nil, name: 'North Carolina', type: 'All Students', state: 'NC', data_source_url: "manual value"}
    manual_data << {is_district: nil, number: nil, name: 'North Carolina', type: 'Public School Students', state: 'NC', data_source_url: "manual value"}
    manual_data << {is_district: nil, number: nil, name: 'NC School of Science & Math', type: nil, state: 'NC', data_source_url: "manual value"}
    manual_data << {is_district: nil, number: nil, name: 'NC School of the Arts', type: nil, state: 'NC', data_source_url: "manual value"}
    manual_data.each do |hash_data|
      NcGeneralInfo.create_and_update!(@run_id, hash_data)
    end
    us_districts = NcGeneralInfo.connection.select_all("select * from us_districts where state = 'NC'")
    us_districts.each do |district|
      hash_data = {
        is_district: 1,
        number: district['number'],
        name: district['name'],
        type: district['type'],
        nces_id: district['nces_id'],
        phone: district['phone'],
        county: district['county'],
        address: district['address'],
        city: district['city'],
        state: district['state'],
        zip: district['zip'],
        zip_4: district['zip_4'],
        data_source_url: "DB01.us_schools_raw.us_districts##{district['id']}"
      }
      hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
      NcGeneralInfo.create_and_update!(@run_id, hash_data)
    end
    us_schools = NcGeneralInfo.connection.select_all("select * from us_schools where state = 'NC'")
    us_schools.each do |school|
      nc_district = NcGeneralInfo.find_by(is_district: 1, number: school['district_number'])
      hash_data = {
        is_district: 0,
        district_id: nc_district&.id,
        number: school['number'],
        name: school['name'],
        type: school['type'],
        low_grade: school['low_grade'],
        high_grade: school['high_grade'],
        charter: school['charter'],
        magnet: school['magnet'],
        title_1_school: school['title_1_school'],
        title_1_school_wide: school['title_1_school_wide'],
        nces_id: school['nces_id'],
        phone: school['phone'],
        county: school['county'],
        address: school['address'],
        city: school['city'],
        state: school['state'],
        zip: school['zip'],
        zip_4: school['zip_4'],
        data_source_url: "DB01.us_schools_raw.us_schools##{school['id']}"
      }
      hash_data.merge!(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
      NcGeneralInfo.create_and_update!(@run_id, hash_data)
    end
  end

  def store_assessment(path)
    xlsx = Roo::Spreadsheet.open(path)
    year = path.match(/\/(\d+-\d+).+/)[1]
    sheet_name = 'Reading and Mathematics Grades'
    sheet = xlsx.sheet(sheet_name)
    records = sheet.parse
    records.each_with_index do |row, ind|
      next if ind < 2
      dist_code, school_code = get_codes(row[1])
      general_info = get_general_info(dist_code, school_code, row[2], "#{sheet_name}##{ind}")
      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: year,
        school_code: row[1],
        aggregation: 'Subject',
        subject_group: 'Mathematics',
        letter: row[12],
        score: row[13],
        achivement_sc: row[14],
        growth_sc: row[15],
        growth: row[16],
        grows_idx: row[17],
        data_source_url: "#{sheet_name}##{ind}"
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:subject_group] = 'Reading'
      hash_data[:letter] = row[6]
      hash_data[:score] = row[7]
      hash_data[:achivement_sc] = row[8]
      hash_data[:growth_sc] = row[9]
      hash_data[:growth] = row[10]
      hash_data[:grows_idx] = row[11]
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
      flush(NcAssessment) if @buffer.count >= 500
    end
    flush(NcAssessment)

    sheet_name = 'Subgroup Letter Grades'
    sheet = xlsx.sheet(sheet_name)
    records = sheet.parse
    records.each_with_index do |row, ind|
      next if ind < 2
      dist_code, school_code = get_codes(row[1])
      general_info = get_general_info(dist_code, school_code, row[2], "#{sheet_name}##{ind}")
      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: year,
        school_code: row[1],
        aggregation: 'Subgroup',
        subject_group: row[6],
        letter: row[7],
        score: row[8],
        achivement_sc: row[9],
        growth_sc: row[10],
        growth: row[11],
        grows_idx: row[12],
        assessment_sc: row[13],
        science_eog_sc: row[14],
        el_progress_sc: row[15],
        '4y_graduation_sc': row[16],
        biology_eoc_sc: row[17],
        act_sc: row[18],
        math_3_sc: row[19],
        data_source_url: "#{sheet_name}##{ind}"
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
      flush(NcAssessment) if @buffer.count >= 500
    end
    flush(NcAssessment)

    sheet_name = 'School Performance Grades'
    sheet = xlsx.sheet(sheet_name)
    records = sheet.parse
    records.each_with_index do |row, ind|
      next if ind < 2
      dist_code, school_code = get_codes(row[1])
      general_info = get_general_info(dist_code, school_code, row[2], "#{sheet_name}##{ind}")
      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: year,
        school_code: row[1],
        aggregation: 'Total',
        subject_group: 'Total',
        letter: row[7],
        score: row[8],
        achivement_sc: row[9],
        growth_sc: row[10],
        growth: row[11],
        grows_idx: row[12],
        assessment_sc: row[13],
        science_eog_sc: row[14],
        el_progress_sc: row[15],
        '4y_graduation_sc': row[16],
        biology_eoc_sc: row[17],
        act_sc: row[18],
        math_3_sc: row[19],
        data_source_url: "#{sheet_name}##{ind}"
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
      flush(NcAssessment) if @buffer.count >= 500
    end
    flush(NcAssessment)
  end
  def store_prev_assessment
    NcUsaRaw.connection.select_all("SELECT * FROM north_carolina_reading_and_mathematics_grades").each do |grade|
      next if !grade['school_code'].presence && !grade['school_name'].presence
      data_source = "DB01.usa_raw.north_carolina_reading_and_mathematics_grades##{grade['id']}"
      dist_code, school_code = get_codes(grade['school_code'])
      general_info = get_general_info(dist_code, school_code, grade['school_name'], data_source)
      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: grade['year'],
        school_code: grade['school_code'],
        aggregation: 'Subject',
        subject_group: 'Mathematics',
        letter: grade['mathematics_letter_grade'],
        score: grade['mathematics_overall_score'],
        achivement_sc: grade['mathematics_achievement_score'],
        growth_sc: grade['mathematics_growth_score'],
        growth: grade['mathematics_growth_status'],
        grows_idx: grade['mathematics_growth_index'],
        data_source_url: data_source
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
      # adding for reading subject
      hash_data[:subject_group] = 'Reading'
      hash_data[:letter] = grade['reading_letter_grade']
      hash_data[:score] = grade['reading_overall_score']
      hash_data[:achivement_sc] = grade['reading_achievement_score']
      hash_data[:growth_sc] = grade['reading_growth_score']
      hash_data[:growth] = grade['reading_growth_status']
      hash_data[:grows_idx] = grade['reading_growth_index']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
      flush(NcAssessment) if @buffer.count >= 500
    end
    flush(NcAssessment)

    NcUsaRaw.connection.select_all("SELECT * FROM north_carolina_subgroup_letter_grades").each do |grade|
      data_source = "DB01.usa_raw.north_carolina_subgroup_letter_grades##{grade['id']}"
      dist_code, school_code = get_codes(grade['school_code'])
      general_info = get_general_info(dist_code, school_code, grade['school_name'], data_source)
      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: grade['year'],
        school_code: grade['school_code'],
        aggregation: 'Subgroup',
        subject_group: grade['subgroup'],
        letter: grade['subgroup_letter_grade'],
        score: grade['subgroup_score'],
        achivement_sc: grade['subgroup_achievement_score'],
        growth_sc: grade['subgroup_growth_score'],
        growth: grade['subgroup_growth_status'],
        grows_idx: grade['subgroup_growth_index'],
        assessment_sc: grade['academic_assessments_score'],
        science_eog_sc: grade['science_eog_score'],
        el_progress_sc: grade['english_learner_progress_score'],
        '4y_graduation_sc': grade['four_year_cohort_graduation_rate_score'],
        biology_eoc_sc: grade['biology_eoc_score'],
        act_sc: grade['act_workkeys_assessments_score'],
        math_3_sc: grade['passing_nc_math_3_course_score'],
        data_source_url: data_source
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      flush(NcAssessment) if @buffer.count >= 500
    end
    flush(NcAssessment)

    NcUsaRaw.connection.select_all("SELECT * FROM north_carolina_school_performance_grades").each do |grade|
      data_source = "DB01.usa_raw.north_carolina_school_performance_grades##{grade['id']}"
      dist_code, school_code = get_codes(grade['school_code'])
      general_info = get_general_info(dist_code, school_code, grade['school_name'], data_source)
      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: grade['year'],
        school_code: grade['school_code'],
        aggregation: 'Total',
        subject_group: 'Total',
        letter: grade['school_performance_grade'],
        score: grade['school_performance_score'],
        achivement_sc: grade['school_achievement_score'],
        growth_sc: grade['school_growth_score'],
        growth: grade['school_growth_status'],
        grows_idx: grade['school_growth_index'],
        assessment_sc: grade['academic_assessments_score'],
        science_eog_sc: grade['science_eog_score'],
        el_progress_sc: grade['english_learner_progress_score'],
        '4y_graduation_sc': grade['four_year_cohort_graduation_rate_score'],
        biology_eoc_sc: grade['biology_eoc_score'],
        act_sc: grade['act_workkeys_assessments_score'],
        math_3_sc: grade['pass_nc_math_3_course_score'],
        data_source_url: data_source
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      flush(NcAssessment) if @buffer.count >= 500
    end
    flush(NcAssessment)
  end

  def store_assessment_act(path)
    start_row = false
    xlsx = Roo::Spreadsheet.open(path)
    year = path.match(/\/(\d+-\d+|\d+–\d+).+/)[1]
    year.gsub!('–', '-')
    grade = path.match(/Seniors/) ? 'Seniors' : 'Grade 11'

    sheet_name = xlsx.sheets[0]
    sheet = xlsx.sheet(sheet_name)
    records = sheet.parse

    flush(NcAssessmentAct)

    records.each_with_index do |row, ind|
      if grade == 'Grade 11'
        start_row = true and next if row[0] == 'System'
        next unless start_row
        next if !row[3].presence

        data_source = "#{sheet_name}##{ind}"
        if row[1] && !row[1].to_s.match(/\w{3}/)
          code_string = row[0].to_s.strip
          code_string = "0#{code_string}" if code_string.length == 2
          dist_code, school_code = get_codes(code_string)
          general_info = get_general_info(dist_code, school_code, row[2], data_source)
        elsif !row[0].presence && !row[1].presence
          general_info = get_general_info(nil, nil, row[2], data_source)
        else
          code_string = row[1].to_s.strip
          code_string = "0#{code_string}" if code_string.length == 5
          code_string = "#{row[0]}#{code_string}" if code_string.length == 3
          dist_code, school_code = get_codes(code_string.strip)
          general_info = get_general_info(dist_code, school_code, row[2], data_source)
        end
        hash_data = {
          touched_run_id: @run_id,
          general_id: general_info.id,
          school_year: year,
          grade: grade,
          subject: 'english',
          number_tested: row[3],
          mean: row[5],
          met_benchmark: row[6],
          data_source_url: data_source
        }
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
        hash_data[:subject] = 'math'
        hash_data[:mean] = row[7]
        hash_data[:met_benchmark] = row[8]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

        hash_data[:subject] = 'reading'
        hash_data[:mean] = row[9]
        hash_data[:met_benchmark] = row[10]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

        hash_data[:subject] = 'science'
        hash_data[:mean] = row[11]
        hash_data[:met_benchmark] = row[12]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

        # hash_data[:subject] = 'writing'
        # hash_data[:mean] = row[14]
        # hash_data[:met_benchmark] = row[15]
        # @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
        flush(NcAssessmentAct) if @buffer.count >= 100
      else
        start_row = true and next if row[2] == 'School System & School'
        next unless start_row
        next if !row[3].presence

        data_source = "#{sheet_name}##{ind}"
        if row[1] && !row[1].to_s.match(/\d{3}$/)
          code_string = row[0].to_s.strip
          code_string = "0#{code_string}" if code_string.length == 2
          dist_code, school_code = get_codes(code_string)
          general_info = get_general_info(dist_code, school_code, row[2] || row[1], data_source)
        elsif row[0].presence && (row[0] == row[1] || !row[1].presence)
          code_string = row[0].to_s.strip
          code_string = "0#{code_string}" if code_string.length == 2
          dist_code, school_code = get_codes(code_string)
          general_info = get_general_info(dist_code, school_code, row[2], data_source)
        elsif !row[0].presence && !row[1].presence
          general_info = get_general_info(nil, nil, row[2],data_source)
        else
          code_string = row[1].to_s.strip
          code_string = "0#{code_string}" if code_string.length == 5
          code_string = "#{row[0]}#{code_string}" if code_string.length == 3
          dist_code, school_code = get_codes(code_string.strip)
          general_info = get_general_info(dist_code, school_code, row[2], data_source)
        end
        hash_data = {
          touched_run_id: @run_id,
          general_id: general_info.id,
          school_year: year,
          grade: 'Seniors',
          subject: 'english',
          mean: row[5],
          met_benchmark: row[6],
          number_tested: row[3],
          data_source_url: data_source
        }
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

        hash_data[:subject] = 'math'
        hash_data[:mean] = row[7]
        hash_data[:met_benchmark] = row[8]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:subject] = 'reading'
        hash_data[:mean] = row[9]
        hash_data[:met_benchmark] = row[10]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:subject] = 'science'
        hash_data[:mean] = row[11]
        hash_data[:met_benchmark] = row[12]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
        flush(NcAssessmentAct) if @buffer.count >= 100
      end
    end
    flush(NcAssessmentAct)
  end
  def store_prev_assessment_act
    NcUsaRaw.connection.select_all("SELECT * FROM north_carolina_act_results_scrape ").each do |grade|
      next unless grade['school'].presence && grade['system_or_school_name'].presence

      data_source = "DB01.usa_raw.north_carolina_act_results_scrape ##{grade['id']}"
      if (grade['system'].nil? || grade['system'] == 'NULL') && (grade['school'].nil? || grade['school'] == 'NULL')
        general_info = get_general_info(nil, nil, grade['system_or_school_name'], data_source)
      elsif grade['system'] && (grade['school'].nil? || grade['school'] == 'NULL')
        code_string = grade['system'].to_s.strip
        code_string = "0#{code_string}" if code_string.length == 2
        dist_code, school_code = get_codes(code_string)
        general_info = get_general_info(dist_code, school_code, grade['system_or_school_name'], data_source)
      else
        code_string = grade['school'].to_s.strip
        code_string = "0#{code_string}" if code_string.length == 5
        code_string = "#{grade['system']}#{code_string}" if code_string.length == 3
        dist_code, school_code = get_codes(code_string.strip)
        general_info = get_general_info(dist_code, school_code, grade['system_or_school_name'], data_source)
      end

      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: grade['year'],
        grade: 'Grade 11',
        subject: 'english',
        mean: grade['english_mean'],
        met_benchmark: grade['met_english_benchmark_percent'],
        number_tested: grade['number_tested'],
        data_source_url: data_source
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:subject] = 'math'
      hash_data[:mean] = grade['math_mean']
      hash_data[:met_benchmark] = grade['met_math_benchmark_percent']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:subject] = 'reading'
      hash_data[:mean] = grade['reading_mean']
      hash_data[:met_benchmark] = grade['met_reading_benchmark_percent']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:subject] = 'science'
      hash_data[:mean] = grade['science_mean']
      hash_data[:met_benchmark] = grade['met_science_benchmark_percent']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:subject] = 'writing'
      hash_data[:mean] = grade['writing_mean']
      hash_data[:met_benchmark] = grade['met_writing_benchmark_percent']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      flush(NcAssessmentAct) if @buffer.count >= 500
    end
    flush(NcAssessmentAct)

    NcUsaRaw.connection.select_all("SELECT * FROM north_carolina_act_graduate_results ").each do |grade|
      next unless grade['school'].presence && grade['system_or_school_name'].presence

      data_source = "DB01.usa_raw.north_carolina_act_graduate_results ##{grade['id']}"
      if (grade['system'].nil? || grade['system'] == 'NULL') && (grade['school'].nil? || grade['school'] == 'NULL')
        general_info = get_general_info(nil, nil, grade['system_or_school_name'], data_source)
      elsif grade['system'] && (grade['school'].nil? || grade['school'] == 'NULL')
        code_string = grade['system'].to_s.strip
        code_string = "0#{code_string}" if code_string.length == 2
        dist_code, school_code = get_codes(code_string)
        general_info = get_general_info(dist_code, school_code, grade['system_or_school_name'], data_source)
      elsif grade['system'] && grade['school'].to_s == '0'
        code_string = grade['system'].to_s.strip
        code_string = "0#{code_string}" if code_string.length == 2
        dist_code, school_code = get_codes(code_string)
        general_info = get_general_info(dist_code, school_code, grade['system_or_school_name'], data_source)
      else
        code_string = grade['school'].to_s.strip
        code_string = "0#{code_string}" if code_string.length == 5
        code_string = "#{grade['system']}#{code_string}" if code_string.length == 3
        dist_code, school_code = get_codes(code_string.strip)
        general_info = get_general_info(dist_code, school_code, grade['system_or_school_name'], data_source)
      end

      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: grade['year'],
        grade: 'Seniors',
        subject: 'english',
        mean: grade['average_english_score'],
        met_benchmark: grade['percent_met_english_benchmark'],
        number_tested: grade['number_tested'],
        data_source_url: data_source
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:subject] = 'math'
      hash_data[:mean] = grade['average_math_score']
      hash_data[:met_benchmark] = grade['percent_met_math_benchmark']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:subject] = 'reading'
      hash_data[:mean] = grade['average_reading_score']
      hash_data[:met_benchmark] = grade['percent_met_reading_benchmark']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:subject] = 'science'
      hash_data[:mean] = grade['average_science_score']
      hash_data[:met_benchmark] = grade['percent_met_science_benchmark']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      flush(NcAssessmentAct) if @buffer.count >= 500
    end
    flush(NcAssessmentAct)
  end

  def store_assessment_ap_sat(path)
    start_row = false
    xlsx = Roo::Spreadsheet.open(path)
    grade = path.match(/SAT Performance/) ? 'SAT' : 'AP'
    year = path.match(/\/(\d+)\s/)[1]
    sheet_name = xlsx.sheets[0]
    sheet = xlsx.sheet(sheet_name)
    records = sheet.parse

    flush(NcAssessmentApSat)

    records.each_with_index do |row, ind|
      data_source = "#{sheet_name}##{ind}"
      if grade == 'SAT'
        start_row = true and next if row[1] == 'School System & School'
        next unless start_row        

        start_col = row[3].presence ? 3 : 5

        next unless row[start_col].presence

        if !row[0].presence && !row[1].presence
          general_info = get_general_info(nil, nil, row[2], data_source)
        elsif row[1] && !row[1].to_s.match(/\d{3}$/)
          code_string = row[0].to_s.strip
          code_string = "0#{code_string}" if code_string.length == 2
          dist_code, school_code = get_codes(code_string)
          general_info = get_general_info(dist_code, school_code, row[2] || row[1], data_source)
        else
          code_string = row[1].to_s.strip
          code_string = "0#{code_string}" if code_string.length == 5
          code_string = "#{row[0]}#{code_string}" if code_string.length == 3
          dist_code, school_code = get_codes(code_string.strip)
          general_info = get_general_info(dist_code, school_code, row[2], data_source)
        end

        hash_data = {
          touched_run_id: @run_id,
          general_id: general_info.id,
          school_year: year,
          test: grade,
          statistics: 'Number Tested',
          number: row[start_col],
          data_source_url: data_source
        }
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Percent Tested'
        hash_data[:number] = row[start_col + 1]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Average Total Score'
        hash_data[:number] = row[start_col + 2]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Average ERW Subtest Score'
        hash_data[:number] = row[start_col + 3]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Average Math Subtest Score'
        hash_data[:number] = row[start_col + 4]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
        flush(NcAssessmentApSat) if @buffer.count >= 100
      else
        start_row = true and next if row[1] == 'School System & School'
        next unless start_row
        next unless row[19].presence

        if !row[0].presence && !row[1].presence
          general_info = get_general_info(nil, nil, row[2], data_source)
        elsif row[1] && !row[1].to_s.match(/\d{3}$/)
          code_string = row[0].to_s.strip
          code_string = "0#{code_string}" if code_string.length == 2
          dist_code, school_code = get_codes(code_string)
          general_info = get_general_info(dist_code, school_code, row[2] || row[1], data_source)
        else
          code_string = row[1].to_s.strip
          code_string = "0#{code_string}" if code_string.length == 5
          code_string = "#{row[0]}#{code_string}" if code_string.length == 3
          dist_code, school_code = get_codes(code_string.strip)
          general_info = get_general_info(dist_code, school_code, row[2], data_source)
        end

        hash_data = {
          touched_run_id: @run_id,
          general_id: general_info.id,
          school_year: year,
          test: grade,
          statistics: 'Number of Test Takers',
          number: row[19],
          data_source_url: data_source
        }
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Participation Rate'
        hash_data[:number] = row[20]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Number of Test-Taker Scoring 3 or Higher'
        hash_data[:number] = row[21]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Percent of Test-Taker Scoring 3 or Higher'
        hash_data[:number] = row[22]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Number of Exams Taken'
        hash_data[:number] = row[23]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Number of Exams with Scores of 3 or Higher'
        hash_data[:number] = row[24]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        hash_data[:statistics] = 'Percent of Exams with Scores of 3 or Higher'
        hash_data[:number] = row[25]
        @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
  
        flush(NcAssessmentApSat) if @buffer.count >= 100
      end
    end

    flush(NcAssessmentApSat)
  end
  def store_prev_assessment_ap_sat
    NcUsaRaw.connection.select_all("SELECT * FROM north_carolina_sat_scores").each do |grade|
      data_source = "DB01.usa_raw.north_carolina_sat_scores ##{grade['id']}"
      if (grade['district_code'].nil? || grade['district_code'].blank?) && (grade['school_code'].nil? || grade['school_code'].blank?)
        general_info = get_general_info(nil, nil, grade['school_name'] || grade['district_name'], data_source)
      elsif grade['district_code'] && (grade['school_code'].nil? || grade['school_code'].blank?)
        code_string = grade['district_code'].to_s.strip
        code_string = grade['district_code'].to_i.to_s.strip if code_string.match(/\.0$/)
        code_string = "0#{code_string}" if code_string.length == 2
        dist_code, school_code = get_codes(code_string)
        general_info = get_general_info(dist_code, school_code, grade['school_name'] || grade['district_name'], data_source)
      else
        dist_code = grade['district_code'].to_s.strip
        dist_code = grade['district_code'].to_i.to_s.strip if dist_code.match(/\.0$/)
        code_string = grade['school_code'].to_s.strip
        code_string = grade['school_code'].to_i.to_s.strip if code_string.match(/\.0$/)
        code_string = "0#{code_string}" if code_string.length == 5
        code_string = "#{dist_code}#{code_string}" if code_string.length == 3
        dist_code, school_code = get_codes(code_string.strip)
        general_info = get_general_info(dist_code, school_code, grade['school_name'] || grade['district_name'], data_source)
      end

      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: grade['year'],
        test: 'SAT',
        statistics: 'Number Tested',
        number: grade['number_tested'],
        data_source_url: data_source
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Percent Tested'
      hash_data[:number] = grade['percent_tested']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Average Total Score'
      hash_data[:number] = grade['total']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Average ERW Subtest Score'
      hash_data[:number] = grade['erw']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Average Math Subtest Score'
      hash_data[:number] = grade['math']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))
      flush(NcAssessmentApSat) if @buffer.count >= 500
    end
    flush(NcAssessmentApSat)
    NcUsaRaw.connection.select_all("SELECT * FROM north_carolina_ap_reports").each do |grade|
      data_source = "DB01.usa_raw.north_carolina_ap_reports ##{grade['id']}"
      if (grade['district_id'].nil? || grade['district_id'].blank?) && (grade['school_code'].nil? || grade['school_code'].blank?)
        general_info = get_general_info(nil, nil, grade['school_name'], data_source)
      elsif grade['district_id'] && (grade['school_code'].nil? || grade['school_code'].blank?)
        code_string = grade['district_id'].to_s.strip
        code_string = grade['district_id'].to_i.to_s.strip if code_string.match(/\.0$/)
        code_string = "0#{code_string}" if code_string.length == 2
        dist_code, school_code = get_codes(code_string)
        general_info = get_general_info(dist_code, school_code, grade['school_name'], data_source)
      else
        dist_code = grade['district_id'].to_s.strip
        dist_code = grade['district_id'].to_i.to_s.strip if dist_code.match(/\.0$/)
        code_string = grade['school_code'].to_s.strip
        code_string = grade['school_code'].to_i.to_s.strip if code_string.match(/\.0$/)
        code_string = "0#{code_string}" if code_string.length == 5
        code_string = "#{dist_code}#{code_string}" if code_string.length == 3
        dist_code, school_code = get_codes(code_string.strip)
        general_info = get_general_info(dist_code, school_code, grade['school_name'], data_source)
      end

      hash_data = {
        touched_run_id: @run_id,
        general_id: general_info.id,
        school_year: grade['year'],
        test: 'AP',
        statistics: 'Number of Test Takers',
        number: grade['numbre_of_test_takers'],
        data_source_url: data_source
      }
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Participation Rate'
      hash_data[:number] = grade['participation_rate']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Number of Test-Taker Scoring 3 or Higher'
      hash_data[:number] = grade['number_of_test_taker_scoring_3_or_higher']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Percent of Test-Taker Scoring 3 or Higher'
      hash_data[:number] = grade['percent_of_test_taker_scoring_3_or_higher']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Number of Exams Taken'
      hash_data[:number] = grade['number_of_exams_taken']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Number of Exams with Scores of 3 or Higher'
      hash_data[:number] = grade['number_of_exams_with_scores_3_or_higher']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      hash_data[:statistics] = 'Percent of Exams with Scores of 3 or Higher'
      hash_data[:number] = grade['percent_of_exams_with_scores_3_or_higher']
      @buffer << hash_data.merge(md5_hash: Digest::MD5.new.hexdigest(hash_data.map{|field| field.to_s}.join))

      flush(NcAssessmentApSat) if @buffer.count >= 500
    end
    flush(NcAssessmentApSat)
  end

  def store_finances(path)
    store_expenditures(path)
    store_salaries(path)
  end

  def store_expenditures(path)
    xlsx = open_xls(path)
    sheet_name = 'Expenditures_byLEA_byPRC'
    exp_sheet  = xlsx.sheet(sheet_name)
    exp_rows = exp_sheet.parse
    lea_list = []
    exp_rows.each_with_index do |row|
      break if row[0].nil? && row[1].nil? && row[2].nil?

      lea_list << row[1]
    end

    prc_list = []
    start_row = false
    year = 2023
    exp_rows.each_with_index do |row, ind|
      if row[0] == 'PRC'
        year_row = exp_rows[ind-2]
        year = year_row[0].match(/(\d+-\d+)/)[1]
        start_row = true
        next
      end
      next unless start_row
      break if row[0].nil? && row[1].nil? && row[2].nil?
      hash_data = {
        school_year: year,
        prc: row[0],
        description: row[1],
        expenditures: row[2]
      }
      prc_list << hash_data
    end

    sheet_name = 'Data Tables'
    data_sheet = xlsx.sheet(sheet_name)
    data_rows = data_sheet.parse

    lea_list.each do |lea|
      school_code = lea.split(' - ')[0][-3, 3]
      school_name = lea.split(' - ')[1]
      general_info = get_general_info(school_code, nil, school_name, lea)
      prc_list.each do |prc_hash|
        key = "#{prc_hash[:prc]}-#{school_code}"
        data_row = data_rows.select{|row| row[0]==key}.first
        prc_hash[:general_id] = general_info.id
        prc_hash[:expenditures] = data_row ? data_row[2] : '-'
        prc_hash[:data_source_url] = key
        @buffer << prc_hash.merge(md5_hash: Digest::MD5.new.hexdigest(prc_hash.map{|field| field.to_s}.join))
        flush(NcFinacesExpenditure) if @buffer.count >= 50
      end
    end
    flush(NcFinacesExpenditure)
  end

  def store_salaries(path)
    xlsx = open_xls(path)
    sheet_name = 'Expenditures_Object Code Detail'
    exp_sheet  = xlsx.sheet(sheet_name)
    exp_rows = exp_sheet.parse
    lea_list = []
    prc_list = []
    exp_rows.each_with_index do |row|
      break if row[0].nil? && row[1].nil? && row[2].nil?

      lea_list << row[1] if row[1]
      prc_list << row[3] if row[3]
    end

    salary_list = []
    start_row = false
    year = 2023
    exp_rows.each_with_index do |row, ind|
      if row[1] == 'Salary'
        year_row = exp_rows[ind-3]
        year = year_row[1].match(/(\d+-\d+)/)[1]
        start_row = true
        next 
      end
      next unless start_row
      next if row[1].nil? || row[1].to_s.length > 5
      next unless row[1].to_s.match(/^\d{3}/)
      break if row[0].nil? && row[1].nil? && row[2].nil?

      hash_data = {
        touched_run_id: @run_id,
        school_year: year,
        code: row[1],
        description: row[2]
      }
      salary_list << hash_data
    end

    sheet_name = 'Data Tables'
    data_sheet = xlsx.sheet(sheet_name)
    data_rows = data_sheet.parse

    lea_list.each do |lea|
      school_code = lea.split(' - ')[0][-3, 3]
      school_name = lea.split(' - ')[1]
      general_info = get_general_info(school_code, nil, school_name, lea)
      prc_list.each do |prc|
        salary_list.each do |salary_hash|
          prc_code = prc.split(' - ')[0][-3, 3]
          key = "#{school_code}-#{prc_code}-#{salary_hash[:code]}"
          data_row = data_rows.select{|row| row[4]==key}.first
          salary_hash[:general_id] = general_info.id
          salary_hash[:expenditures] = data_row ? data_row[5] : '-'
          salary_hash[:data_source_url] = key
        end
        total_value = salary_list.map{|s| s[:expenditures]}.reject{|v| v=='-'}.sum
        salary_list.each do |salary_hash|
          percent = ((salary_hash[:expenditures] / total_value) *100 ).round(2) rescue '0.00'
          salary_hash[:percent] = "#{percent}%"
          salary_hash[:expenditures] = salary_hash[:expenditures].round unless salary_hash[:expenditures] == '-'
          @buffer << salary_hash.merge(md5_hash: Digest::MD5.new.hexdigest(salary_hash.map{|field| field.to_s}.join))
          flush(NcFinancesSalary) if @buffer.count >= 50
        end
      end
    end
    flush(NcFinancesSalary)
  end

  def flush(object)
    data_array = []
    run_ids = Hash[object.where( md5_hash: @buffer.map { |h| h[:md5_hash] } ).map { |r| [r.md5_hash, r.run_id] }]
    @buffer.each do |hash|
      data_array << hash.merge(run_id: run_ids[hash[:md5_hash]] || @run_id, updated_at: Time.now)
    end
    object.upsert_all(data_array) if data_array.any?
    @buffer = []
  end

  def get_general_info(dist_code, school_code, school_name, data_source)
    school_name = school_name.strip if school_name
    if dist_code.presence && school_code.presence
      general_info = NcGeneralInfo.where("number='#{school_code}' AND district_id IN (SELECT id FROM nc_general_info WHERE number='#{dist_code}' AND is_district=1)").first
      dist_general_info = NcGeneralInfo.where(number: dist_code, is_district: 1).first
      unless general_info
        if dist_general_info
          hash_data = {district_id: dist_general_info.id, number: school_code, name: school_name, data_source_url: data_source}
        else
          dist_hash = {is_district: 1, number: dist_code, name: school_name, data_source_url: data_source}
          dist_general_info = NcGeneralInfo.create_and_update!(@run_id, dist_hash)
          hash_data = {district_id: dist_general_info.id, number: school_code, name: school_name, data_source_url: data_source}
        end
        general_info = NcGeneralInfo.create_and_update!(@run_id, hash_data)
      end
    elsif dist_code && !school_code.presence
      general_info = NcGeneralInfo.find_by(number: dist_code, is_district: 1)
      unless general_info
        dist_hash = {is_district: 1, number: dist_code, name: school_name, data_source_url: data_source}
        general_info = NcGeneralInfo.create_and_update!(@run_id, dist_hash)
      end
    elsif !dist_code.presence && !school_code.presence && school_name
      school_name = 'NC School of Science & Math' if school_name == 'NC School of Science and Math'
      if school_name == 'State' || school_name == 'State of North Carolina' || school_name == 'Sum of all LEA Expenditures' || school_name == 'North Carolina'
        general_info = NcGeneralInfo.find_by(number: 0, name: 'North Carolina', type: 'State')
      elsif school_name.match(/NC School Of Science & Math/i) || school_name.match(/NC School Of The Arts/i)
        general_info = NcGeneralInfo.where("LOWER(name)=?", school_name.strip.downcase).first
      elsif school_name.match(/.*\(\w.*\)/)
        name = school_name.match(/(.*)\((\w.+)\)/)[1]
        name = 'North Carolina' if name.match(/North Carolina/)
        type = school_name.match(/(.*)\((\w.+)\)/)[2].split.first
        general_info = NcGeneralInfo.where("LOWER(name)=? AND LOWER(type) LIKE ?", name.strip.downcase, "%#{type.strip.downcase}%").first
      end
      unless general_info
        dist_hash = {name: school_name, data_source_url: data_source}
        general_info = NcGeneralInfo.create_and_update!(@run_id, dist_hash)
      end
    end
    
    logger.info "dist_code: #{dist_code}, school_code:#{school_code}, school_name:#{school_name}" unless general_info
    general_info
  end

  def get_codes(code_string)
    logger.info "code_string: #{code_string}=====" unless [3,5,6].include?(code_string.length)
    code_string = code_string.to_s.strip
    dist_code = code_string.match(/^(\w{3})/)[1]
    school_code = code_string.match(/(\w{3}$)/)[1]
    if code_string.length == 5
      code_string = "0#{code_string}"
      dist_code = code_string.match(/^(\w{3})/)[1]
      school_code = code_string.match(/(\w{3}$)/)[1]
    elsif code_string.length == 3
      school_code = nil
    end
    [dist_code, school_code]
  end
  def finish
    @run_object.finish
  end

  def open_xls(path)
    if path.match(/\.xls$/)
      Roo::Excel.new(path)
    else
      Roo::Spreadsheet.open(path)
    end
  end
end
