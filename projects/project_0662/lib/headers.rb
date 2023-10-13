module Headers
  def safety_headers
    {:"0" => {:classroom_removal => "classroom removal", :in_school_suspension => "in school suspension", :received_one_out_suspension => "received one out of school suspension", :received_multiple_out_suspension => "received mutliple out of school suspension", :total_out_suspension => "total out of school suspension", :expulsion_with_services => "expulsion with service", :expulsion_without_services => "expulsion without service", :referrals_law_enforcement => "referrals to law enforcement", :school_related_arrest => "school related arrest", :other_action => "other action", :undublicated_student_disciplined => "unduplicated"}}
  end

  def ratio_headers
    {:"0" => {:pk_12_count => "pk-12", :position_head_count => "position", :position_fte => "fte"}, :"1" => {:pupil_position_fte_ration => "fte"}}
  end

  def attendance_headers
    {:"0" => {:attendance_rate => "attendance rate", :truancy_rate => "truancy", :total_days_attended => "days attended", :total_days_excused_absence => "excused", :total_days_unexcused_absence => "unexcused", :total_days_possible_attendance => "days possible"}}
  end

  def graduation_headers
    {:final_grad_base => "", :graduates_total => "", :graduation_rate => "", :completers_total => "", :completion_rate => ""}
  end

  def race_headers
    {:pupil_count => "", :dropouts => "", :dropout_rate => ""}
  end

  def cmas_headers
    {:"0" => {:total_records => "records", :valid_scores => "valid", :no_scores => "no scores", :parcipation_rate => "participation rate", :mean_scale_score => "mean scale", :standart_deviation => "standard deviation", :not_yet_meet_count => "number did not yet meet expectations", :partially_met_count => "number partially met expectations", :approached_count => "number approached expectations", :met_count => "number met expectations", :met_and_exceeded_count => "met or exceeded expectations", :exceeded_count => "number exceeded expectations"}, :"1" => {:not_yet_meet_percent => "did not yet meet expectations", :partially_met_percent => "partially met expectations", :approached_percent => "approached expectations", :met_percent => "met expectations", :met_and_exceeded_percent => "met or exceeded expectations", :exceeded_percent => "exceeded expectations"}}
  end

  def make_model
    {:"0" => {:psat => "CoSat", :cmas => "CoCmas", :attendance => "CoAttendance", :salary => "CoSalary", :student => "CoRatio", :suspension => "CoSafety", :dropout => "CoDropout", :graduation => "CoGraduation"}, :"1" => {:dropout => "CoSocial", :graduation => "CoGradSocial"}}
  end
end
