# frozen_string_literal: true
require 'roo'
require 'roo-xls'

class Parser < Hamster::Parser

  def get_links(page,id)
    page.css("##{id} option").map{|e| e['value']}.reject{|e| e=='#'}
  end

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def get_district_ids(response)
    page = parse_page(response)
    page.css('#DistrictId option').map{|e| e['value']}.reject{|e| e.empty?} rescue []
  end

  def get_csv_link(response)
    page = parse_page(response)
    page.css('a').select{|e| e['href'].downcase.include? 'downloadcsv'}.first['href'] rescue nil
  end

  def get_school_ids(response)
    begin
      page = JSON.parse(response)
      page.map{|e| e['Value']}
    rescue
      []
    end
  end

  def parse_enrolment_files(file,ids_and_names,run_id)
    data_array = []
    school_year = file.split('/').last.scan(/\d{4}/).first
    school_year = "#{school_year}-#{school_year.to_i + 1}"
    school_year = "2018-2019" if (school_year.nil?)
    rows = (file.include? 'pdf') ? read_pdf(file) : read_excel(file)
    headers = rows.select{|e| e.join.downcase.include? 'kg'}.first.reject{|e| e.nil?}.map{|e| e.downcase.squish} rescue nil
    return [] if (headers.nil?)
    grades = ['PK','Total PK-12']
    rows.each do |row|
      next if (check_wrong_value(row,'kg'))
      if (file.include? 'pdf')
        next if ((row.join.scan(/\d/).count < 14) && ((row.count == 1) && (row.join.downcase.exclude? 'school')))
      else
        next if (row.join.scan(/\d/).count < 14)
      end
      district_name = (file.include? 'pdf') ? row.first.squish : get_value(row,headers,'district')
      grades.each_with_index do |grade,index|
        data_hash = {}
        data_hash[:general_id] = get_general_id(district_name,ids_and_names)
        data_hash[:general_id] = data_array.last[:general_id] if (data_hash[:general_id].nil?) rescue nil
        data_hash[:school_year] = school_year
        data_hash[:ethnicity] = (file.include? 'pdf') ? row.first.squish : get_value(row,headers,'ethnic')
        data_hash[:ethnicity] = nil if (check_ethnicity_value(district_name,ids_and_names))
        data_hash[:grade] = grade
        data_hash[:run_id] = run_id
        data_hash[:touched_run_id] = run_id
        if (index == 0)
          data_hash[:count] = (file.include? 'pdf') ? row.second : get_value(row,headers,'pk')
        else
          data_hash[:count] = row.last.to_s.squish
        end
        data_hash = mark_empty_as_nil(data_hash)
        data_array << data_hash
      end
    end
    data_array.reject{|e| (e[:count].nil? || e[:count].scan(/\d/).empty?)}
  end

  def parse_graduation_files(file,ids_and_names,run_id)
    data_array = []
    grads_col = ["district", "school", "graduate","cohort", "rate"]
    rows = (file.include? 'pdf') ? read_pdf(file) : read_excel(file)
    headers = rows.select{|e| e.join.downcase.include? 'graduate'}.first.reject{|e| e.nil?}.map{|e| e.downcase.squish}
    headers = headers.join('  ').split.select{|e| grads_col.any?{|word| e.include? word}}
    if file.include? 'pdf'
      years_list = rows.first.first.scan(/\d{4}/)
      school_year = "#{years_list.first}-#{years_list.last}" 
    elsif file.include? '2019'
      school_year = '2018-2019'
    else
      year = file.split('/').last.scan(/\d{4}/).first
      school_year = "#{year.to_i - 1}-#{year}"
    end
    graduation = ((file.downcase.include? '4_year') || (file.downcase.include? 'fouryear')) ? 'Four Year' : 'Five Year'
    rows.each do |row|
      next if ((check_wrong_value(row,'graduate')) || (check_wrong_value(row,'adjusted')) || (check_wrong_value(row,'prepare')) || (check_wrong_value(row,'page')))
      data_hash = {}
      data_hash[:general_id] = get_general_id(get_value(row,headers,'district'),ids_and_names)
      data_hash[:general_id] = get_general_id(get_value(row,headers,'school'),ids_and_names) if (data_hash[:general_id].nil?)
      data_hash[:graduates] = get_value(row,headers,'graduate')
      data_hash[:cohort] = get_value(row,headers,'cohort')
      data_hash[:rate_percent] = get_value(row,headers,'rate')
      data_hash[:graduation] = graduation
      data_hash[:school_year] = school_year
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array.reject{|e| e[:graduates].nil?}
  end

  def parse_revenue_files(file,ids_and_names,run_id)
    data_array = []
    year = file.split('/').last.scan(/\d{2}/).first
    school_year = "20#{year.to_i-1}-20#{year}"
    rows = (file.include? 'pdf') ? read_pdf(file) : read_excel(file)
    headers = rows.select{|e| e.join.downcase.include? 'local'}.first.map{|e| e.to_s.downcase.squish}
    rows.each do |row|
      next if (check_wrong_value(row,'local'))
      next if (row.join.scan(/\d/).count < 10)
      district_name = get_value(row,headers,'district')
      data_hash = {}
      data_hash[:general_id] = get_id_for_revenue(district_name,ids_and_names)
      data_hash[:revenues_type] = 'Revenue total excluding PERS/TRS'
      data_hash[:type] = get_value(row,headers,'type')
      data_hash[:adm] = get_value(row,headers,'adm')
      data_hash[:op_fund_local] = get_value(row,headers,'local')
      data_hash[:op_fund_state] = get_value(row,headers,'state')
      data_hash[:op_fund_federal] = get_value(row,headers,'federal')
      data_hash[:op_fund_other] = get_value(row,headers,'other')
      data_hash[:special_rev_funds] = get_value(row,headers,'revenue')
      data_hash[:total_revenue] = get_value(row,headers,'total')
      data_hash[:special_rev_funds] = get_value(row,headers,'funds') if ((data_hash[:special_rev_funds].nil?) || data_hash[:special_rev_funds] == data_hash[:total_revenue])
      data_hash[:pupil_trans] = get_value(row,headers,'pupil')
      data_hash[:pupil_trans] = get_value(row,headers,'transportation') if (data_hash[:pupil_trans].nil?)
      data_hash[:school_year] = school_year
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array
  end

  def parse_assessment_files(file,ids_and_names,run_id)
    data_array = []
    rows = read_csv_file(file)
    headers = rows.select{|e| e.join.downcase.include? 'percent'}.first.map{|e| e.to_s.downcase.squish} rescue nil
    return [] if (headers.nil?)
    years = file.split('/').last.scan(/\d{4}/).select{|e| e[1] == '0'}
    school_year = "#{years.first}-#{years.last}"
    rows.each do |row|
      next if (check_wrong_value(row,'percent'))
      next if (row.join.scan(/\d/).count < 10)
      keys = ['state','school','district']
      keys.each do |key|
        group_name = get_value(row,headers,'group')
        data_hash = {}
        data_hash[:general_id] = get_general_id(group_name,ids_and_names)
        data_hash[:school_year] = school_year
        data_hash[:subject] = get_value(row,headers,'subject')
        data_hash[:demographic] = get_value(row,headers,'demographic')
        data_hash[:advanced_percent] = get_value(row,headers,"advanced#{key}")
        data_hash[:proficient_percent] = get_value(row,headers,"proficient#{key}")
        data_hash[:approaching_proficient_percent] = get_value(row,headers,"approachingproficient#{key}")
        data_hash[:needs_support_percent] = get_value(row,headers,"needssupport#{key}")
        data_hash[:total_tested] = get_value(row,headers,"totaltested#{key}")
        data_hash[:percent_tested] = get_value(row,headers,"percenttested#{key}")
        data_hash[:run_id] = run_id
        data_hash[:touched_run_id] = run_id
        data_hash = mark_empty_as_nil(data_hash)
        data_array << data_hash
      end
    end
    data_array
  end

  def parse_teachers_count_files(file,ids_and_names,run_id)
    data_array = []
    rows = read_excel(file)
    headers = rows.select{|e| e.join.downcase.include? 'ratio'}.first.map{|e| e.to_s.downcase.squish} rescue nil
    return [] if (headers.nil?)
    last_year = file.split('/').last.scan(/\d{4}/).select{|e| e.include? '20'}.last
    school_year = "#{last_year.to_i - 1}-#{last_year}"
    rows.each do |row|
      next if (row.join.scan(/\d/).count < 12)
      district_name = get_value(row,headers,'district')
      data_hash = {}
      data_hash[:general_id] = get_general_id(district_name,ids_and_names)
      data_hash[:general_id] = get_general_id(get_value(row,headers,'school'),ids_and_names) if ((data_hash[:general_id].nil?) && (file.include? 'xlsx'))
      data_hash[:general_id] = data_array.last[:general_id] if (data_hash[:general_id].nil?) rescue nil
      data_hash[:school_year] = school_year
      data_hash[:remedial_specialist_count] = get_value(row,headers,'remedial specialist count')
      data_hash[:remedial_specialist_fte] = get_value(row,headers,'remedial specialist fte')
      data_hash[:head_teacher_count] = get_value(row,headers,'head teacher count')
      data_hash[:head_teacher_fte] = get_value(row,headers,'head teacher fte')
      data_hash[:teacher_count] = get_value(row,headers,'teacher count')
      data_hash[:teacher_fte] = get_value(row,headers,'teacher fte')
      data_hash[:visiting_teacher_count] = get_value(row,headers,'visiting teacher count')
      data_hash[:visiting_teacher_count] = get_value(row,headers,'visiting/ itinerant teacher count') if (data_hash[:visiting_teacher_count].nil?)
      data_hash[:visiting_teacher_fte] = get_value(row,headers,'visiting teacher fte')
      data_hash[:visiting_teacher_fte] = get_value(row,headers,'visiting/ itinerant teacher fte') if (data_hash[:visiting_teacher_fte].nil?)
      data_hash[:sped_teacher_count] = get_value(row,headers,'sped teacher count')
      data_hash[:sped_teacher_fte] = get_value(row,headers,'sped teacher fte')
      data_hash[:esl_teacher_count] = get_value(row,headers,'esl teacher count')
      data_hash[:esl_teacher_fte] = get_value(row,headers,'esl teacher fte')
      data_hash[:onsite_supervis_teacher_count] = get_value(row,headers,'on-site supervising teacher count')
      data_hash[:onsite_supervis_teacher_count] = get_value(row,headers,'on-site teacher count') if (data_hash[:onsite_supervis_teacher_count].nil?)
      data_hash[:onsite_supervis_teacher_fte] = get_value(row,headers,'on-site supervising teacher fte')
      data_hash[:onsite_supervis_teacher_fte] = get_value(row,headers,'on-site teacher fte') if (data_hash[:onsite_supervis_teacher_fte].nil?)
      data_hash[:correspond_teacher_count] = get_value(row,headers,'correspondence teacher count')
      data_hash[:correspond_teacher_fte] = get_value(row,headers,'correspondence teacher fte')
      data_hash[:online_course_fac_teacher_count] = get_value(row,headers,'online course facilitator teacher count')
      data_hash[:online_course_fac_teacher_fte] = get_value(row,headers,'online course facilitator teacher fte')
      data_hash[:associate_teacher_count] = get_value(row,headers,'associate teacher count')
      data_hash[:associate_teacher_fte] = get_value(row,headers,'associate teacher fte')
      data_hash[:total_teacher_count] = get_value(row,headers,'total teacher count')
      data_hash[:total_teacher_fte] = get_value(row,headers,'total teacher fte')
      data_hash[:total_students_kg_12] = get_value(row,headers,'total student kg-12')
      data_hash[:total_students_pk_12] = get_value(row,headers,'total student pk-12')
      data_hash[:total_students_pk_12] = get_value(row,headers,'total student pe-12') if (data_hash[:total_students_pk_12].nil?)
      data_hash[:student_teacher_ratio] = get_value(row,headers,'ratio')
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    data_array
  end

  private

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def get_value(row,headers,key)
    value_index = headers.index(headers.select{ |e| e.include? key }.first)
    row[value_index].to_s.squish unless value_index.nil?
  end

  def check_wrong_value(row,key)
    return true if (row.join.downcase.include? key)
    false
  end

  def get_general_id(key,ids_and_names)
    key = 'none' if (key.nil?)
    required_array = ids_and_names.select{ |e| e.last.downcase == key.downcase }.first
    required_array.first unless required_array.nil?
  end

  def read_excel(file)
    doc = (file.include? 'xlsx') ? Roo::Spreadsheet.open(file) : Roo::Excel.new(file)
    doc.sheet(doc.default_sheet)
  end

  def read_pdf(file)
    reader = PDF::Reader.new(open(file))
    rows = reader.pages.map{|page| page.text.scan(/^.+/)}.flatten.map{|e| e.split('  ').reject{|e| e.empty?}}
    rows.reject{|e| ((e.join.downcase.include? 'kg') && (e.count < 8))}
  end

  def check_ethnicity_value(key,ids_and_names)
    key = 'none' if (key.nil?)
    return false if (ids_and_names.select{ |e| e.last.downcase == key.downcase }.first.nil?)
    true
  end

  def get_id_for_revenue(key,ids_and_names)
    key = 'none' if (key.nil?)
    required_array = ids_and_names.select{|e| e.last.downcase.include? key.downcase}.first if (required_array.nil?)
    required_array.first unless required_array.nil?
  end

  def read_csv_file(file)
    CSV.foreach(file)
  end

end
