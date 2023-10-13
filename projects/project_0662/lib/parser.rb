# frozen_string_literal" => true
require_relative '../lib/headers'
require_relative '../lib/parser_helper'
require 'roo'
class Parser < Hamster::Parser
  include Headers
  include ParserHelper

  def parse_html(request)
    Nokogiri::HTML(request.force_encoding('utf-8'))
  end

  def get_inner_page_links(main_page, text1, text2)
    main_page.css("a").select{ |e| e.text.downcase.include? text1 and e.text.downcase.include? text2}.map{ |a| a["href"]}
  end

  def get_links(main_page, text)
    main_page.css("a").select{ |e| e.text.downcase.include? text}.map{ |a| a["href"]}
  end

  def get_graduation_links(main_page)
    main_page.css("div.shadeddiv").css("a")[0..6].map{ |a| a["href"]}
  end

  def get_inner_links(main_page, text, current_link)
    links = []
    links << main_page.css("a").select{|a| a.text.downcase.include? text}[0..4].map{ |a| a["href"]}
    links << current_link
    links.flatten
  end

  def get_suspension_link(main_page)
    main_page.css(".field-item ul")[0].css("a").map{ |a| a["href"]}
  end

  def get_staff_link(main_page)
    salary_links  = main_page.css(".field-item").css("a").select{|a| a.text.include? "XLS" }[0..2].map{ |a| a["href"]}
    student_links = main_page.css(".field-item").css("a").select{|a| (a.text.include? "Licensed Psychologist to Student Ratios") || (a.text.include? "Student Teacher Ratios (XLS)")}.reject{ |a| a.text.include? "PDF"}.map{ |a| a["href"]}
    [salary_links, student_links]
  end

  def get_data(path, run_id, file, sheet_name, get_ids)
    data_array = []
    xsl = get_xls_sheets(path)
    xsl.sheets.each_with_index do |value,index_1|
      if ((value.downcase.include? sheet_name) || (value.downcase.include? "district"))
        data_lines, ind = (value.downcase.include? "district") ? get_rows(xsl, index_1, "scores") : get_rows(xsl, index_1, "district code")
        data_lines.each_with_index do |data, index|
          next if index <= ind

          data_hash = {}
          data_hash[:general_id]                     = make_general_id(data_lines, data, ind, get_data_column(data_lines, data, ind, "level", 0), get_ids)
          data_hash[:school_year]                    = get_year(file)
          data_hash[:subject]                        = get_subject(data_lines, data, ind, "content", 0)
          data_hash[:grade]                          = get_grade(data_lines, data, ind, "grade", 0)
          headers_details                            = cmas_headers
          date_hash                                  = get_updated_hash(headers_details, data_lines, data, ind)
          data_hash.update(date_hash)
          data_hash.update(make_columns(data_hash, file, run_id))
          data_array << data_hash
        end
      end
    end
    data_array
  end

  def get_race(path, run_id, file, sheet_name, get_ids, flag)
    data_array = []
    xsl = get_xls_sheets(path)
    xsl.sheets.each_with_index do |value,index_1|
      if value.downcase.include? sheet_name
        data_lines, ind = get_rows(xsl, index_1, "organization name")
        count = get_count(data_lines, ind, "student")
        data_lines.each_with_index do |data, index|
          next if iterator(index, ind, data_lines)

          (0..23).each do |index_count|
            data_hash = {}
            data_hash[:general_id]                        = make_general_id_other(data_lines, data, ind, "school code", "organization code", get_ids)
            data_hash[:school_year]                       = get_year(file)
            if flag == 0
              gender, race                                = get_race_gender(data_lines, ind, count, index_count, 5, "Final")
              next if race.nil?

              data_hash[:race]                            = (race.include? "All") ? "Total" : race
              data_hash[:gender]                          = gender
              data_hash[:anticipated_year_of_graduation]  = get_data_column(data_lines, data, ind, "year of", 0)
              data_hash[:year_after_entering_high_school] = get_data_column(data_lines, data, ind, "number ", 0)
              data_hash.update(make_hash_headers(data, index_count, count, 0, 5))
            else
              data_hash[:grade]                          = get_data_column(data_lines, data, ind, "grade", 0)
              gender, race                               = get_race_gender(data_lines, ind, count, index_count, 3, "Pupil")
              next if race.nil?

              data_hash[:race]                           = race.empty? ? "Total" : race
              data_hash[:gender]                         = gender
              data_hash.update(make_hash_headers(data, index_count, count, 0, 3))
            end
            data_hash.update(make_columns(data_hash, file, run_id))
            data_array << data_hash
          end
        end
      end
    end
    data_array
  end

  def get_social(path, run_id, file, sheet_name, get_ids, flag)
    data_array = []
    xsl = get_xls_sheets(path)
    xsl.sheets.each_with_index do |value,index_1|
      if value.downcase.include? sheet_name
        data_lines, ind = get_rows(xsl, index_1, "organization name")
        count = data_lines[ind].index data_lines[ind].select{ |a| a.to_s.downcase.include? "student"}[0]
        data_lines.each_with_index do |data, index|
          next if iterator(index, ind, data_lines)

          (0..6).each do |index_count|
            data_hash = {}
            data_hash[:general_id]                        = make_general_id_other(data_lines, data, ind, "school code", "organization code", get_ids)
            data_hash[:school_year]                       = get_year(file)
            if flag == 0
              data_hash[:group]                           = data_lines[ind][(3*index_count)+count].split("Pupil").first
              data_hash.update(make_hash_headers(data, index_count, count, 1, 3))
            else
              data_hash[:group]                           = data_lines[ind][(5*index_count)+count].split("Final").first
              data_hash[:anticipated_year_of_graduation]  = get_data_column(data_lines, data, ind, "year of", 0)
              data_hash[:year_after_entering_high_school] = get_data_column(data_lines, data, ind, "number ", 0)
              data_hash.update(make_hash_headers(data, index_count, count, 1, 5))
            end
            data_hash.update(make_columns(data_hash, file, run_id))
            data_array << data_hash
          end
        end
      end
    end
    data_array
  end

  def get_data_attendance(path, run_id, file, get_ids)
    data_array = []
    xsl = get_xls_sheets(path)
    xsl.sheets.each_with_index do |value,index_1|
      if index_1 == 0
        data_lines, ind = get_rows(xsl, index_1, "school code")
        data_lines.each_with_index do |data, index|
          next if iterator(index, ind, data_lines)

          data_hash = {}
          data_hash[:general_id]                     = make_general_id_other(data_lines, data, ind, "school code", "district code", get_ids)
          data_hash[:school_year]                    = get_year(file)
          students_counted                           = get_data_column(data_lines, data, ind, "students counted", 0)
          data_hash[:students_counted]               = (students_counted.nil?) ? get_data_column(data_lines, data, ind, "enrollment", 0) : students_counted
          length                                     = get_data_column(data_lines, data, ind, "session reported", 0)
          data_hash[:total_days_in_session_reported] = (length.nil?) ? get_data_column(data_lines, data, ind, "length", 0) : length
          headers_details                            = attendance_headers
          date_hash                                  = get_updated_hash(headers_details, data_lines, data, ind)
          data_hash.update(date_hash)
          data_hash.update(make_columns(data_hash, file, run_id))
          data_array << data_hash
        end
      end
    end
    data_array
  end

  def get_data_salary(path, run_id, file, get_ids)
    data_array = []
    xsl = get_xls_sheets(path)
    xsl.sheets.each_with_index do |value,index_1|
      if index_1 == 0
        data_lines, ind = get_rows(xsl, index_1, "total fte")
        checker = data_lines.index(data_lines.select { |e| (e.to_s.include? 'All Schools') && (e.to_s.include? "Charter")}[0])
        end_index = checker.nil? ? 0 : checker-1
        count = data_lines[ind].index data_lines[ind].select{ |a| a.to_s.downcase.include? "total fte"}[0]
        data_lines.each_with_index do |data, index|
          next if iterator(index, ind, data_lines)

          (0..end_index).each do |index_count|
            data_hash = {}
            data_hash[:general_id]                       = make_general_id_other(data_lines, data, ind, "organization code", "", get_ids)
            data_hash[:school_year]                      = data_lines[1][0].split.first
            data_hash[:position]                         = data_lines[1][0].split("FTE").first.split[1..-1].join(" ")
            data_hash[:school_type]                      = data_lines[checker].select{ |a| a.to_s.downcase.include? "school"}[index_count] rescue nil
            data_hash[:total_fte]                        = data[(2*index_count)+count+1]
            data_hash[:average_salary]                   = data[(2*index_count)+count+2]
            data_hash.update(make_columns(data_hash, file, run_id))
            data_array << data_hash
          end
        end
      end
    end
    data_array
  end

  def get_student_ratio(path, run_id, file, get_ids)
    data_array = []
    xsl = get_xls_sheets(path)
    xsl.sheets.each_with_index do |value,index_1|
      if index_1 == 0
        data_lines, ind = get_rows(xsl, index_1, "count")
        data_lines.each_with_index do |data, index|
          next if iterator(index, ind, data_lines)

          data_hash = {}
          data_hash[:general_id]                        = make_general_id_other(data_lines, data, ind, "organization code", "", get_ids)
          data_hash[:school_year]                       = data_lines[1][0].split.first
          data_hash[:position]                          = (data_lines[1][0].include? "Teacher") ? "Teacher" : "Licensed Psychologist"
          headers_details                               = ratio_headers
          date_hash                                     = get_updated_hash(headers_details, data_lines, data, ind)
          data_hash.update(date_hash)
          data_hash.update(make_columns(data_hash, file, run_id))
          data_array << data_hash
        end
      end
    end
    data_array
  end

  def get_safety(path, run_id, file, get_ids)
    data_array = []
    xsl = get_xls_sheets(path)
    xsl.sheets.each_with_index do |value,index_1|
      if index_1 == 0
        data_lines, ind = get_rows(xsl, index_1, "district code")
        data_lines.each_with_index do |data, index|
          next if iterator(index, ind, data_lines)

          data_hash = {}
          data_hash[:general_id]                        = make_general_id_other(data_lines, data, ind, "district code", "", get_ids)
          data_hash[:school_year]                       = data_lines[0][0].split.first
          category                                      = get_data_column(data_lines, data, ind, "categories", 0)
          data_hash[:category]                          = category.nil? ? get_data_column(data_lines, data, ind, "race", 0) : category
          headers_details                               = safety_headers
          date_hash                                     = get_updated_hash(headers_details, data_lines, data, ind)
          data_hash.update(date_hash)
          data_hash.update(make_columns(data_hash, file, run_id))
          data_array << data_hash
        end
      end
    end
    data_array
  end

  private

  def make_hash_headers(data, index_count, count, flag, value)
    date_hash = (flag == 0)? race_headers : graduation_headers
    date_hash.keys.each_with_index do |key, index_4|
      date_hash[key] = data[(value*index_count)+count+index_4]
    end
    date_hash
  end

  def get_count(data_lines, ind, option)
    data_lines[ind].index data_lines[ind].select{ |a| a.to_s.downcase.include? option}[0]
  end

  def get_updated_hash(headers_details, data_lines, data, ind)
    data_hash = {}
    headers_details.each do |key, value|
      value.each do |key_index,counter|
        data_hash[key_index] = get_data_column(data_lines, data, ind, counter, key.to_s.to_i)
      end
    end
    data_hash
  end

  def get_race_gender(data_lines, ind, count, index_count, multiplyer, text)
    gender = make_gender(data_lines[ind][(multiplyer*index_count)+count])
    race = data_lines[ind][(3*index_count)+count].split("#{text}").first.split("#{gender}").first rescue nil
    [gender, race]
  end

  def get_subject(data_lines, data, index, attribute, number)
    subject = get_data_column(data_lines, data, index, attribute, number)
    subject = (!(subject.scan(/[0-9]/).empty?) || (subject == "NA") || (subject == "- -")) ? get_data_column(data_lines, data, index, "subject", number) : subject rescue nil
    (!(subject.scan(/[0-9]/).empty?) || (subject == "NA") || (subject == "- -")) ? nil : subject rescue nil
  end

  def get_grade(data_lines, data, index, attribute, number)
    grade = get_data_column(data_lines, data, index, attribute, number)
    grade.nil? ? get_data_column(data_lines, data, index, "test", number) : grade rescue nil
  end

  def get_data_column(data_lines, data, index, attribute, number)
    data[data_lines[index].index data_lines[index].select{ |a| a.to_s.squish.downcase.include? "#{attribute}"}[number]].to_s.squish rescue nil
  end

  def make_gender(data)
    return if data.nil?
    if data.include? "Male"
      return "Male"
    elsif data.include? "Female"
      return "Female"
    else
      return "Total"
    end
  end
end
