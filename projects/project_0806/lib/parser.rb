# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_html(body)
    Nokogiri::HTML(body)
  end

  def parse_json(body)
    JSON.parse(body)
  end

  def pdf_data_parser(pdf_pages, file_name, run_id)
    data_hash = {}
    pdf_pages.each_with_index do |page, ind|
      page_in_txt = page.text
      data_hash["pct_read_proficiency_all_students"] = get_proficiency_all_students("READ", /Just\s*\d+/, page_in_txt)
      data_hash["pct_math_proficiency_all_students"] = get_proficiency_all_students("MATH", /Just\s*\d+/, page_in_txt)
      data_hash["pct_student_proficiency_white"] = get_proficiency_with_race("White", page_in_txt)
      data_hash["pct_student_proficiency_hispanic"] = get_proficiency_with_race("Hispanic", page_in_txt)
      data_hash["pct_student_proficiency_black"] = get_proficiency_with_race("Black", page_in_txt)
      data_hash["pct_student_proficiency_asian"] = get_proficiency_with_race("Asian", page_in_txt)
      data_hash["pct_teachers_rating"] = get_proficiency_with_race("ofdistrict", page_in_txt)
      gradudate = page_in_txt.split("graduate")
      data_hash["pct_graduation_rating"] = gradudate.count == 3 ? gradudate.second.split.last : ""
      data_hash["pct_graduation_read_proficiency_rating"] = gradudate.count == 3 ? page_in_txt.split("teachersarerated").last.split("areproficient").first.scan(/\d+\%/).first : ""
      data_hash["pct_grade_3rd_reading_proficiency"] = pct_grade_reading_proficiency(page_in_txt, "3rdGrade", gradudate)
      data_hash["pct_grade_4th_reading_proficiency"] = pct_grade_reading_proficiency(page_in_txt, "4thGrade", gradudate)
      data_hash["pct_grade_5th_reading_proficiency"] = pct_grade_reading_proficiency(page_in_txt, "5thGrade", gradudate)
      data_hash["pct_grade_6th_reading_proficiency"] = pct_grade_reading_proficiency(page_in_txt, "6thGrade", gradudate)
      data_hash["pct_grade_7th_reading_proficiency"] = pct_grade_reading_proficiency(page_in_txt, "7thGrade", gradudate)
      data_hash["pct_grade_8th_reading_proficiency"] = pct_grade_reading_proficiency(page_in_txt, "8thGrade", gradudate)
      mechigan_2nd_last = page_in_txt.split("Michigan").first.split[-2]
      if mechigan_2nd_last == "+" or mechigan_2nd_last == "-" 
        data_hash["pct_property_tax_2010_vs_2021"] = page_in_txt.split("Michigan").first.split[-2..-1].join
      else
        data_hash["pct_property_tax_2010_vs_2021"] = page_in_txt.split("Michigan").first.split.last
      end
      home_value = page_in_txt.split("Kentucky").first.split("3\n").last.split[0..1].join
      data_hash["pct_median_home_value_2010_vs_2021"] = home_value.match?(/[+-]\s*\d+\s*\%\S*/) ? home_value.scan(/[+-]\s*\d+\s*\%/).first : home_value.include?("NA") ? "" : ""
      data_hash["pct_student_enrollment_2010_vs_2021"] = page_in_txt.scan(/[+-]\s*\d+\s*%/).last
      row_of_spending = page_in_txt.split("studentinthecountry.").last.split("Getengaged!")
      if gradudate.count == 3 
        data_hash["pct_spending_student_2010_vs_2021"] = row_of_spending.first.squish.match?(/^[+-]\s*\d+\s*%$/) ? row_of_spending.first : ""
      else
        spending_pct = row_of_spending.first.scan(/\d+%/).last
        spending_pct_sign = row_of_spending.first.scan(/\s*[+-]\s*/).last
        data_hash["pct_spending_student_2010_vs_2021"] = "#{spending_pct_sign}#{spending_pct}"
      end
      data_hash["spending_per_student_2010"] = get_spending_per_student_year(page_in_txt, /2010:\$\S+/, "2010:")
      data_hash["spending_per_student_2021"] = get_spending_per_student_year(page_in_txt, /2021:\$\S+/, "2021:")
      data_hash["spending_per_student_illinois_2020"] = get_spending_per_student_district(page_in_txt, /\$\S+\s+Illinois/).first
      data_hash["spending_per_student_michigan_2020"] = get_spending_per_student_district(page_in_txt, /Michigan\s+\$\S+/).last
      data_hash["spending_per_student_wisconsin_2020"] = get_spending_per_student_district(page_in_txt, /Wisconsin\s+\$\S+/).last
      data_hash["spending_per_student_iowa_2020"] = get_spending_per_student_district(page_in_txt, /Iowa\s+\$\S+/).last
      data_hash["spending_per_student_kentucky_2020"] = get_spending_per_student_district(page_in_txt, /Kentucky\s+\$\S+/).last
      data_hash["spending_per_student_missouri_2020"] = get_spending_per_student_district(page_in_txt, /Missouri\s+\$\S+/).last
      data_hash["spending_per_student_indiana_2020"] = get_spending_per_student_district(page_in_txt, /Indiana\s+\$\S+/).last
      data_hash = mark_empty_as_nil(data_hash)
      data_hash["district"] = file_name.gsub("_", " ")
      data_hash["md5_hash"] = create_md5_hash(data_hash)
      data_hash["data_source_url"] = "https://wirepoints.org/school-district-report-cards/district-report-cards/"
      data_hash["run_id"] = run_id
    end
    data_hash
  end

  private 

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? or value == "NA" ) ? nil : value.to_s.squish.gsub("%", "").gsub(" ", "").gsub("Just", "").gsub("$","")}
  end

  def get_proficiency_all_students(split_txt, scan_regex, page_in_txt)
    splitting = page_in_txt.split(split_txt).first.scan(scan_regex)
    split_txt == "MATH" ? splitting.last : splitting.first
  end

  def get_proficiency_with_race(split_txt, page_in_txt)
    value = page_in_txt.split(split_txt).first.split.last
    value.size > 10 ? "" : value
  end

  def pct_grade_reading_proficiency(page_in_txt, split_txt, gradudate)
    gradudate.count == 1 ? page_in_txt.split(split_txt).last.split.first : ""
  end

  def get_spending_per_student_year(page_in_txt, scan_regex, gsub_txt)
    page_in_txt.scan(scan_regex).empty? ? "" : page_in_txt.scan(scan_regex).first.gsub(gsub_txt,"")
  end

  def get_spending_per_student_district(page_in_txt, scan_regex)
    page_in_txt.scan(scan_regex).first.split
  end
  
end