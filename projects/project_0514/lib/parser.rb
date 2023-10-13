# frozen_string_literal" => true
require 'creek'
class Parser < Hamster::Parser

  def get_file_name(json, year)
    data = JSON.parse(json)
    data.select{|a| a["Year"] == year}.last["FileName"] rescue nil
  end

  def get_header(headers, search_header)
    headers.select{|k, v| v if v == search_header}
  end

  def get_parsed_json(path,year,run_id)
    creek = Creek::Book.new (path)
    sheet = creek.sheets.first
    data_array = []
    headers = sheet.rows.first
    column_array = get_hash
    sheet.rows.each_with_index do |row, index|
      next if index == 0
      data_hash = {}
      column_array.each do |key, value|
        header_extract = get_header(headers, value)
        cell = header_extract.keys.first
        digit = cell.scan(/\d+/).first.to_i + index
        cell = cell.gsub(cell.scan(/\d+/).first, digit.to_s)
        data_hash[:"#{key}"] = row[cell]
      end
      data_hash[:year] = year
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_array << data_hash
    end
    data_array
  end

  private

  def get_hash
    {
      "unit_id" => "unitid",
      "institution_name" => "institution_name",
      "address1" => "addr1_txt",
      "address2" => "addr2_txt",
      "city" => "city_txt",
      "state" => "state_cd",
      "zip" => "zip_text",
      "classification_code" => "ClassificationCode",
      "classification_name" => "classification_name",
      "ef_male_count" => "EFMaleCount",
      "ef_female_count" => "EFFemaleCount",
      "ef_total_count" => "EFTotalCount",
      "sector_code" => "sector_cd",
      "sector_name" => "sector_name",
      "student_aid_men" => "STUDENTAID_MEN",
      "student_aid_women" => "STUDENTAID_WOMEN",
      "student_aid_coed" => "STUDENTAID_COED",
      "student_aid_total" => "STUDENTAID_TOTAL",
      "aid_men_ratio" => "STUAID_MEN_RATIO",
      "aid_women_ratio" => "STUAID_WOMEN_RATIO",
      "aid_coed_ratio" => "STUAID_COED_RATIO",
      "hd_coach_sal_men" => "HDCOACH_SALARY_MEN",
      "hd_coach_sal_women" => "HDCOACH_SALARY_WOMEN",
      "hd_coach_sal_coed" => "HDCOACH_SALARY_COED",
      "num_hd_coach_men" => "NUM_HDCOACH_MEN",
      "num_hd_coach_women" => "NUM_HDCOACH_WOMEN",
      "num_hd_coach_coed" => "NUM_HDCOACH_COED",
      "hd_coach_sal_fte_men" => "HDCOACH_SAL_FTE_MEN",
      "hd_coach_sal_fte_women" => "HDCOACH_SAL_FTE_WOMN",
      "hd_coach_sal_fte_coed" => "HDCOACH_SAL_FTE_COED",
      "fte_hd_coach_men" => "FTE_HDCOACH_MEN",
      "fte_hd_coach_women" => "FTE_HDCOACH_WOMEN",
      "fte_hd_coach_coed" => "FTE_HDCOACH_COED",
      "num_as_coach_men" => "NUM_ASCOACH_MEN",
      "num_as_coach_women" => "NUM_ASCOACH_WOMEN",
      "num_as_coach_coed" => "NUM_ASCOACH_COED",
      "as_coach_sal_men" => "ASCOACH_SALARY_MEN",
      "as_coach_sal_women" => "ASCOACH_SALARY_WOMEN",
      "as_coach_sal_coed" => "ASCOACH_SALARY_COED",
      "as_coach_sal_fte_men" => "ASCOACH_SAL_FTE_MEN",
      "as_coach_sal_fte_women" => "ASCOACH_SAL_FTE_WOMN",
      "as_coach_sal_fte_coed" => "ASCOACH_SAL_FTE_COED",
      "fte_as_coach_men" => "FTE_ASCOACH_MEN",
      "fte_as_coach_women" => "FTE_ASCOACH_WOMEN",
      "fte_as_coach_coed" => "FTE_ASCOACH_COED",
      "undup_ct_patric_men" => "UNDUP_CT_PARTIC_MEN",
      "undup_ct_patric_women" => "UNDUP_CT_PARTIC_WOMEN",
      "total_exp_all_notalloc" => "TOT_EXPENSE_ALL_NOTALLOC",
      "grand_total_revenue" => "GRND_TOTAL_REVENUE",
      "total_exp_bskball" => "TOTAL_EXP_MENWOMEN_Bskball",
      "exp_men_bskball" => "EXPENSE_MENALL_Bskball",
      "exp_women_bskball" => "EXPENSE_WOMENALL_Bskball",
      "total_exp_football" => "TOTAL_EXP_MENWOMEN_Football",
      "exp_men_football" => "EXP_MEN_Football",
      "exp_women_football" => "EXP_WOMEN_Football",
      "grand_total_expense" => "GRND_TOTAL_EXPENSE",
    }
  end
end
