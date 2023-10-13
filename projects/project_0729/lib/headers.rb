module Headers
  def salary_headers
    {:temporary_id => "", :regular_wages => "", :overtime_wages => "", :other_wages => "", :total_wages => ""}
  end

  def payroll_headers
    {
      :temporary_id => "", :record_number => "", :agency_number => "", :agency_name => "", :department_number => "", :department_name => "", :branch_code => "",
      :branch_name => "", :job_code => "", :job_title => "", :location_number => "", :location_name => "", :reg_temp_code => "", :reg_temp_desc => "", :classified_code => "",
      :classified_desc => "", :original_hire_date => "", :last_hire_date => "", :job_entry_date => "", :full_part_time_code => "", :full_part_time_desc => "", 
      :salary_plan_grid => "", :salary_grade_range => "", :max_salary_step => "", :compensation_rate => "", :comp_frequency_code => "", :comp_frequency_desc => "",
      :position_fte => "", :bargaining_unit_number => "", :bargaining_unit_name => "", :active_on => ""
    }
  end
end
