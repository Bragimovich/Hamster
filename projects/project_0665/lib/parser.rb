# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_json(response)
    JSON.parse(response)
  end

  def get_data(content, run_id)
    page = parse_json(content)
    data_array = []
    page.each do |record|
      data_hash = {}
      data_hash[:Payment_fiscal_year]   = record["pyrl_fiscal_yr"].to_i
      data_hash[:Calendar_Year]         = record["calendar_year"].to_i
      data_hash[:Dept_ID]               = record["deptid"]
      data_hash[:Employee_ID]           = record["emplid_empl_rcd"]
      data_hash[:First_Name]            = record["first_name"]
      data_hash[:Middle_name]           = record["middle_initial"]
      data_hash[:Last_Name]             = record["last_name"]
      data_hash[:Name_suffix]           = record["name_suffix"] rescue nil
      data_hash[:Check]                 = record["check"].to_i
      data_hash[:Check_Date]            = Date.parse(record["check_dt"]) rescue nil
      data_hash[:Check_option]          = record["chk_option"]
      data_hash[:Check_Status]          = record["chk_status"]
      data_hash[:Annual_rate]           = record["annual_rate"].to_f
      data_hash[:Be_week_comp_rate]     = record["bi_weekly_comp_rate"].to_f
      data_hash[:Other]                 = record["other"].to_i
      data_hash[:Fringe]                = record["fringe"].to_f
      data_hash[:Overtime]              = record["overtime"].to_i
      data_hash[:Salary_wages]          = record["salaries_wages"].to_f
      data_hash[:fringe_amt_no_retire]  = record["fringe_amt_no_retire"].to_f
      data_hash[:SERS_amount]           = record["sers_amount"].to_f
      data_hash[:ARP_amount]            = record["arp_amount"].to_i
      data_hash[:Teachers_amount]       = record["teachers_amount"].to_i
      data_hash[:Judges_amount]         = record["judges_amount"].to_i
      data_hash[:Total_gross ]          = record["tot_gross"].to_f
      data_hash[:Age]                   = record["age"].to_i
      data_hash[:Job_Code_description]  = record["job_cd_descr"]
      data_hash[:ee_class_descr]        = record["ee_class_descr"]
      data_hash[:job_indicator]         = record["job_indicator"]
      data_hash[:Ethnicity]             = record["ethnic_grp"]
      data_hash[:Sex]                   = record["sex"]
      data_hash[:Full_Part]             = record["full_part"]
      data_hash[:Hire_date]             = Date.parse(record["orig_hire"]) rescue nil
      data_hash[:Termination_date]      = record["term_date"] rescue nil
      data_hash[:City]                  = record["city"]
      data_hash[:postal]                = record["postal"]
      data_hash[:State]                 = record["state"]
      data_hash[:Union]                 = record["union_descr"]
      data_hash[:Agency]                = record["agency"]
      data_hash[:md5_hash]              = create_md5_hash(data_hash)
      data_hash[:run_id]                = run_id
      data_hash[:touched_run_id]    	  = run_id
      data_array << data_hash
    end
    data_array
  end

  private

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
